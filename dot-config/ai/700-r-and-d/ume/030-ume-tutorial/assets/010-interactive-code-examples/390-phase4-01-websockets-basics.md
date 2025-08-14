# WebSockets Basics

:::interactive-code
title: Understanding WebSockets Basics
description: This example demonstrates the fundamental concepts of WebSockets, including connection establishment, message exchange, and error handling.
language: javascript
editable: true
code: |
  // This is a client-side JavaScript example of WebSocket usage
  
  // Create a WebSocket connection
  function createWebSocketConnection(url) {
    console.log(`Connecting to WebSocket server at ${url}...`);
    
    // Create a new WebSocket instance
    const socket = new WebSocket(url);
    
    // Connection opened
    socket.addEventListener('open', (event) => {
      console.log('Connection established!');
      
      // Send a message to the server
      const message = {
        type: 'hello',
        content: 'Hello, WebSocket server!',
        timestamp: new Date().toISOString()
      };
      
      socket.send(JSON.stringify(message));
      console.log('Sent message:', message);
    });
    
    // Listen for messages from the server
    socket.addEventListener('message', (event) => {
      try {
        const message = JSON.parse(event.data);
        console.log('Received message:', message);
        
        // Handle different message types
        switch (message.type) {
          case 'welcome':
            console.log(`Server says: ${message.content}`);
            break;
            
          case 'notification':
            console.log(`Notification: ${message.content}`);
            break;
            
          case 'update':
            console.log(`Update received for ${message.entity}:`, message.data);
            break;
            
          default:
            console.log('Unknown message type:', message.type);
        }
      } catch (error) {
        console.error('Error parsing message:', error);
        console.log('Raw message:', event.data);
      }
    });
    
    // Handle errors
    socket.addEventListener('error', (event) => {
      console.error('WebSocket error:', event);
    });
    
    // Connection closed
    socket.addEventListener('close', (event) => {
      console.log(`Connection closed. Code: ${event.code}, Reason: ${event.reason}`);
      
      if (event.code !== 1000) {
        // 1000 is the code for normal closure
        console.log('Connection closed abnormally. Attempting to reconnect...');
        setTimeout(() => {
          createWebSocketConnection(url);
        }, 3000); // Reconnect after 3 seconds
      }
    });
    
    return socket;
  }
  
  // Function to send a message through the WebSocket
  function sendMessage(socket, type, content, additionalData = {}) {
    if (socket.readyState !== WebSocket.OPEN) {
      console.error('Cannot send message: WebSocket is not open');
      return false;
    }
    
    const message = {
      type,
      content,
      timestamp: new Date().toISOString(),
      ...additionalData
    };
    
    socket.send(JSON.stringify(message));
    console.log('Sent message:', message);
    return true;
  }
  
  // Function to subscribe to a channel
  function subscribeToChannel(socket, channel) {
    return sendMessage(socket, 'subscribe', `Subscribing to ${channel}`, { channel });
  }
  
  // Function to unsubscribe from a channel
  function unsubscribeFromChannel(socket, channel) {
    return sendMessage(socket, 'unsubscribe', `Unsubscribing from ${channel}`, { channel });
  }
  
  // Function to close the WebSocket connection
  function closeConnection(socket, reason = 'User initiated closure') {
    if (socket.readyState === WebSocket.OPEN) {
      socket.close(1000, reason);
      console.log(`Closing connection: ${reason}`);
      return true;
    }
    
    console.error('Cannot close: WebSocket is not open');
    return false;
  }
  
  // Simulate WebSocket server responses
  function simulateServerResponses(socket) {
    // Simulate welcome message from server
    setTimeout(() => {
      const welcomeMessage = {
        type: 'welcome',
        content: 'Welcome to the WebSocket server!',
        timestamp: new Date().toISOString()
      };
      
      // In a real scenario, this would come from the server
      // Here we're simulating it by triggering a message event
      const messageEvent = new MessageEvent('message', {
        data: JSON.stringify(welcomeMessage)
      });
      
      socket.dispatchEvent(messageEvent);
    }, 500);
    
    // Simulate notification after subscription
    setTimeout(() => {
      const notificationMessage = {
        type: 'notification',
        content: 'You have successfully subscribed to the channel',
        timestamp: new Date().toISOString()
      };
      
      const messageEvent = new MessageEvent('message', {
        data: JSON.stringify(notificationMessage)
      });
      
      socket.dispatchEvent(messageEvent);
    }, 2000);
    
    // Simulate data update
    setTimeout(() => {
      const updateMessage = {
        type: 'update',
        entity: 'user',
        data: {
          id: 123,
          name: 'John Doe',
          status: 'online'
        },
        timestamp: new Date().toISOString()
      };
      
      const messageEvent = new MessageEvent('message', {
        data: JSON.stringify(updateMessage)
      });
      
      socket.dispatchEvent(messageEvent);
    }, 3500);
  }
  
  // Main function to demonstrate WebSocket usage
  function demonstrateWebSockets() {
    console.log('WebSocket Demonstration');
    console.log('----------------------');
    
    // In a real application, this would be your WebSocket server URL
    // For this example, we'll use a mock URL
    const wsUrl = 'wss://example.com/ws';
    
    // Create a mock WebSocket for demonstration
    // In a browser environment, this would be a real WebSocket
    class MockWebSocket extends EventTarget {
      constructor(url) {
        super();
        this.url = url;
        this.readyState = WebSocket.CONNECTING;
        
        // Simulate connection establishment
        setTimeout(() => {
          this.readyState = WebSocket.OPEN;
          this.dispatchEvent(new Event('open'));
        }, 300);
      }
      
      send(data) {
        // In a real WebSocket, this would send data to the server
        console.log(`[MockWebSocket] Sending data: ${data}`);
      }
      
      close(code = 1000, reason = '') {
        this.readyState = WebSocket.CLOSING;
        
        setTimeout(() => {
          this.readyState = WebSocket.CLOSED;
          this.dispatchEvent(new CloseEvent('close', { code, reason }));
        }, 200);
      }
    }
    
    // Define WebSocket constants
    WebSocket = {
      CONNECTING: 0,
      OPEN: 1,
      CLOSING: 2,
      CLOSED: 3
    };
    
    // Create a mock WebSocket connection
    const socket = new MockWebSocket(wsUrl);
    
    // Use our WebSocket wrapper function
    const wsConnection = createWebSocketConnection(wsUrl);
    
    // Simulate server responses
    simulateServerResponses(socket);
    
    // Demonstrate subscribing to a channel
    setTimeout(() => {
      console.log('\nSubscribing to channel...');
      subscribeToChannel(socket, 'user-presence');
    }, 1000);
    
    // Demonstrate sending a custom message
    setTimeout(() => {
      console.log('\nSending a custom message...');
      sendMessage(socket, 'chat', 'Hello everyone!', { room: 'general' });
    }, 3000);
    
    // Demonstrate unsubscribing from a channel
    setTimeout(() => {
      console.log('\nUnsubscribing from channel...');
      unsubscribeFromChannel(socket, 'user-presence');
    }, 4000);
    
    // Demonstrate closing the connection
    setTimeout(() => {
      console.log('\nClosing the connection...');
      closeConnection(socket, 'Demo completed');
    }, 5000);
  }
  
  // Run the demonstration
  demonstrateWebSockets();
explanation: |
  This example demonstrates the fundamental concepts of WebSockets:
  
  1. **Connection Establishment**: Creating a WebSocket connection to a server.
  
  2. **Event Handling**: Setting up event listeners for:
     - `open`: When the connection is established
     - `message`: When a message is received from the server
     - `error`: When an error occurs
     - `close`: When the connection is closed
  
  3. **Message Exchange**: Sending and receiving messages in JSON format.
  
  4. **Message Types**: Handling different types of messages:
     - Welcome messages
     - Notifications
     - Data updates
  
  5. **Channel Subscription**: Subscribing and unsubscribing from channels.
  
  6. **Error Handling**: Handling connection errors and parsing errors.
  
  7. **Reconnection Logic**: Automatically reconnecting when the connection is closed abnormally.
  
  Key WebSocket concepts illustrated:
  
  - **Full-Duplex Communication**: WebSockets allow both the client and server to send messages at any time.
  
  - **Persistent Connection**: Unlike HTTP, WebSockets maintain a persistent connection.
  
  - **Low Overhead**: After the initial handshake, WebSockets have minimal header overhead.
  
  - **Real-Time Updates**: WebSockets enable real-time updates without polling.
  
  In a real Laravel application with Reverb:
  - The WebSocket server would be powered by Laravel Reverb
  - Authentication would be handled through Laravel's authentication system
  - Channels would be defined in your Laravel application
  - Events would be broadcast using Laravel's event broadcasting system
challenges:
  - Add authentication to the WebSocket connection using a token
  - Implement a heartbeat mechanism to detect connection issues
  - Create a message queue for messages that couldn't be sent due to connection issues
  - Add support for binary messages (e.g., for sending files)
  - Implement a presence system that shows which users are currently connected
:::
