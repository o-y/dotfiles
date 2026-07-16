use clap::{Parser, ValueEnum};

pub mod appearance;
pub mod bottombar;
pub mod config;
pub mod constants;
pub mod tabs;
pub mod vcs;

#[derive(ValueEnum, Debug, Clone, Copy, PartialEq, Eq)]
pub enum RetrieveTarget {
    #[value(name = "bottombar_formatted")]
    BottombarFormatted,
    #[value(name = "bottombar_pill")]
    BottombarPill,
    #[value(name = "tab_icon")]
    TabIcon,
    #[value(name = "tab_name")]
    TabName,
    #[value(name = "tab_colour")]
    TabColour,
    #[value(name = "tab_formatted")]
    TabFormatted,
    #[value(name = "tab_pill_active")]
    TabPillActive,
    #[value(name = "tab_pill_inactive")]
    TabPillInactive,
    #[value(name = "vcs_icon")]
    VcsIcon,
    #[value(name = "vcs_branch")]
    VcsBranch,
    #[value(name = "vcs_colour")]
    VcsColour,
    #[value(name = "vcs_formatted")]
    VcsFormatted,
    #[value(name = "vcs_pill")]
    VcsPill,
}

#[derive(Parser, Debug, PartialEq, Eq)]
#[command(version, about, long_about = None)]
pub struct Args {
    #[arg(
        short = 'p',
        long,
        default_value = "",
        help = "Name of the currently running process (e.g. zsh, cargo, nvim, gradle, etc.)"
    )]
    pub process_name: String,

    #[arg(short = 'd', long, help = "The current working directory of the pane")]
    pub working_directory: String,

    #[arg(
        short = 'c',
        long,
        help = "The number of panes open in the current window",
        default_value_t = 1,
        value_parser = clap::value_parser!(u8).range(1..)
    )]
    pub pane_count: u8,

    #[arg(
        short = 't',
        long,
        help = "The current title of the pane (#{pane_title})",
        default_value = ""
    )]
    pub pane_title: String,

    #[arg(
        short = 'P',
        long,
        help = "The process ID (PID) of the current pane (#{pane_pid})"
    )]
    pub pane_pid: Option<u32>,

    #[arg(
        short = 'r',
        long,
        help = "Defines what metadata should be retrieved given the process name and directory"
    )]
    pub retrieve: RetrieveTarget,

    #[arg(
        short = 'v',
        long,
        help = "Whether to enable verbose logging",
        default_value_t = false
    )]
    pub verbose: bool,
}

fn main() {
    let args = Args::parse();

    match args.retrieve {
        RetrieveTarget::VcsIcon
        | RetrieveTarget::VcsBranch
        | RetrieveTarget::VcsColour
        | RetrieveTarget::VcsFormatted
        | RetrieveTarget::VcsPill => {
            println!("{}", vcs::output::render(args.retrieve, &args.working_directory));
        }
        RetrieveTarget::BottombarFormatted | RetrieveTarget::BottombarPill => {
            println!(
                "{}",
                bottombar::output::render(
                    args.retrieve,
                    args.pane_pid,
                    &args.working_directory,
                    &args.process_name
                )
            );
        }
        RetrieveTarget::TabIcon
        | RetrieveTarget::TabName
        | RetrieveTarget::TabColour
        | RetrieveTarget::TabFormatted
        | RetrieveTarget::TabPillActive
        | RetrieveTarget::TabPillInactive => match config::parser::AppConfig::load() {
            Ok(app_config) => {
                println!(
                    "{}",
                    tabs::output::render(
                        args.retrieve,
                        &args.process_name,
                        &args.working_directory,
                        args.pane_count,
                        &args.pane_title,
                        &app_config
                    )
                );
            }
            Err(e) => {
                if args.verbose {
                    eprintln!("[autoname] encountered exception: {}", e);
                }
                println!("{}", tabs::output::render_error(args.retrieve));
                std::process::exit(1);
            }
        },
    }
}