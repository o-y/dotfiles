import React, { createContext, useContext, useState, useCallback, useRef } from 'react';
import { Box, Text } from 'ink';

interface NotificationContextType {
  showNotification: (message: string, duration?: number) => void;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

export function NotificationProvider({ children }: { children: React.ReactNode }) {
  const [message, setMessage] = useState<string | null>(null);
  const timeoutRef = useRef<Timer | null>(null);

  const showNotification = useCallback((msg: string, duration = 3000) => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    setMessage(msg);
    timeoutRef.current = setTimeout(() => {
      setMessage(null);
      timeoutRef.current = null;
    }, duration);
  }, []);

  return (
    <NotificationContext.Provider value={{ showNotification }}>
      <Box flexDirection="column" width="100%" height="100%">
        <Box flexDirection="column" flexGrow={1}>
          {children}
        </Box>
        {message && (
          <Box marginLeft={2} marginBottom={1}>
            <Box 
              borderStyle="round" 
              borderColor="cyan" 
              paddingX={1}
              flexDirection="row"
              alignItems="center"
            >
              <Text color="cyan" bold>✓ </Text>
              <Text bold> {message} </Text>
            </Box>
          </Box>
        )}
      </Box>
    </NotificationContext.Provider>
  );
}

export function useNotification() {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotification must be used within a NotificationProvider');
  }
  return context;
}
