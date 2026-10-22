/// Ubah respons list JSON menjadi list model.
List<T> parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) =>
    (data as List).map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();