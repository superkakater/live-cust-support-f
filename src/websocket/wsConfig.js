let stompClient = null;

export function setStompClient(client) {
  stompClient = client;
}

export function getStompClient() {
  return stompClient;
}

export function disconnectStompClient() {
  if (stompClient && stompClient.connected) {
    stompClient.disconnect(() => {});
  }
  stompClient = null;
}
