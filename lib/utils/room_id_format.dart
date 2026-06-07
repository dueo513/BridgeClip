String compactRoomId(String roomId) {
  if (roomId.length <= 18) return roomId;
  return '${roomId.substring(0, 11)}...${roomId.substring(roomId.length - 4)}';
}
