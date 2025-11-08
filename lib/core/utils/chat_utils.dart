class ChatUtils {
static String getChatRoomIdByUsername(String a, String b) {
    // Comparamos las cadenas completas. 
    // compareTo devuelve > 0 si 'a' es "mayor" que 'b' alfabéticamente.
     if (a.compareTo(b) > 0) {
      return "$b\_$a";
    } else {
       return "$a\_$b";
   }
  }

  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
