/**
 * Core tree data structure used for visualizing targets and their directory groupings.
 */
export interface TreeNode<T = unknown> {
  name: string;
  fullPath: string;
  isTarget: boolean;
  children: Map<string, TreeNode<T>>;
  isExpanded: boolean;
  data: T;
}

/**
 * Builds a prefix tree of paths, allowing generic data to be attached to leaves (targets)
 * and intermediary folders.
 *
 * @param targets The list of string paths (e.g. `foo/bar:baz`).
 * @param leafDataFactory Callback to instantiate data for target nodes.
 * @param folderDataFactory Callback to instantiate data for directory nodes.
 * @returns The root TreeNode.
 */
export function buildTargetTree<T>(
  targets: string[],
  leafDataFactory: (target: string) => T,
  folderDataFactory: () => T,
): TreeNode<T> {
  const root: TreeNode<T> = { 
    name: 'root', 
    fullPath: '', 
    isTarget: false, 
    children: new Map(), 
    isExpanded: true, 
    data: folderDataFactory() 
  };
  
  for (const target of targets) {
    const [pkgPath = '', ruleName = ''] = target.replace(/^\/\//, '').split(':');
    const segments = pkgPath.split('/').filter(Boolean);
    
    let current = root;
    for (const segment of segments) {
      if (!current.children.has(segment)) {
        current.children.set(segment, { 
          name: segment, 
          fullPath: '', 
          isTarget: false, 
          children: new Map(), 
          isExpanded: true, 
          data: folderDataFactory() 
        });
      }
      current = current.children.get(segment)!;
    }
    
    current.children.set(target, {
      name: ruleName || pkgPath,
      fullPath: target,
      isTarget: true,
      children: new Map(),
      isExpanded: true,
      data: leafDataFactory(target)
    });
  }
  return root;
}

/**
 * Compresses the tree in-place by merging linear unbranching directory paths
 * (e.g., `foo` -> `bar` becomes `foo/bar`).
 *
 * @param node The current node to compress.
 * @param isRoot Whether the current node is the root directory.
 */
export function compressTree<T>(node: TreeNode<T>, isRoot = false): void {
  if (node.isTarget) return;

  if (!isRoot) {
    while (node.children.size === 1) {
      const onlyChild = Array.from(node.children.values())[0];
      if (!onlyChild || onlyChild.isTarget) break;
      node.name = `${node.name}/${onlyChild.name}`;
      node.children = onlyChild.children;
    }
  }

  for (const child of node.children.values()) {
    compressTree(child);
  }
}

/**
 * Flattens the visible portion of the tree into a linear array for list-based rendering.
 *
 * @param node The node to start traversing from.
 * @param depth The current visual depth.
 * @param flatNodes The mutating array of collected nodes.
 * @param sortFn Comparator for sibling nodes.
 */
export function flattenTree<T>(
  node: TreeNode<T>,
  depth: number,
  flatNodes: { node: TreeNode<T>; depth: number }[],
  sortFn: (a: TreeNode<T>, b: TreeNode<T>) => number
): void {
  const sortedChildren = Array.from(node.children.values()).sort(sortFn);
  for (const child of sortedChildren) {
    flatNodes.push({ node: child, depth });
    if (!child.isTarget && child.isExpanded) {
      flattenTree(child, depth + 1, flatNodes, sortFn);
    }
  }
}

/**
 * Recursively extracts all fullPath string values from the tree leaves.
 *
 * @param node The node to start extracting from.
 * @param allTargets Mutating array to collect the targets.
 */
export function extractAllTargets<T>(node: TreeNode<T>, allTargets: string[]): void {
  if (node.isTarget) allTargets.push(node.fullPath);
  node.children.forEach(child => extractAllTargets(child, allTargets));
}
