class ChatUtils {
  static String getChatRoomIdByUsername(String a, String b) {
    
    // --- INICIO DE LA CORRECCIÓN ---
    // Forzamos ambos apodos a MAYÚSCULAS antes de comparar.
    // Esto asegura que "Usuario1" y "usuario1" se traten como iguales.
    String upperA = a.toUpperCase();
    String upperB = b.toUpperCase();
    // --- FIN DE LA CORRECCIÓN ---

    // Comparamos las cadenas completas en mayúsculas.
    if (upperA.compareTo(upperB) > 0) {
      // Si A es "mayor", B va primero
      return "$upperB\_$upperA";
    } else {
      // Si A es "menor" o igual, A va primero
      return "$upperA\_$upperB";
    }
  }
}
