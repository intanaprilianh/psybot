class Professional {
  final String? id;
  final String name;
  final String title;
  final String profession;
  final String category;
  final String price;
  final String description;
  final int experienceYears;
  final int patients;
  final int reviews;
  final bool availableToday;
  bool isFavorite;

  Professional({
    this.id,
    required this.name,
    required this.title,
    required this.profession,
    required this.category,
    required this.price,
    required this.description,
    required this.experienceYears,
    required this.patients,
    required this.reviews,
    required this.availableToday,
    this.isFavorite = false,
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>?;
    final nama = users?['nama'] as String? ?? 'Profesional';
    final spesialisasi = json['spesialisasi'] as String? ?? '';
    final tarif = json['tarif_per_sesi'] as int? ?? 0;
    final gratis = json['tarif_gratis'] as bool? ?? false;
    final rating = (json['rating'] as num?)?.toDouble() ?? 0;
    final totalSesi = json['total_sesi'] as int? ?? 0;
    final online = json['status_online'] as bool? ?? false;

    String titleText;
    String categoryText;
    switch (spesialisasi) {
      case 'psikiater':
        titleText = 'Psikiater';
        categoryText = 'Dokter';
        break;
      case 'psikolog':
        titleText = 'Psikolog Klinis';
        categoryText = 'Psikolog';
        break;
      case 'konselor':
        titleText = 'Konselor';
        categoryText = 'Konselor';
        break;
      default:
        titleText = spesialisasi;
        categoryText = spesialisasi;
    }

    return Professional(
      id: json['id'] as String?,
      name: nama,
      title: titleText,
      profession: categoryText,
      category: categoryText,
      price: gratis ? 'Gratis' : 'Rp ${_formatPrice(tarif)}/sesi',
      description: json['bio'] as String? ?? '',
      experienceYears: 0,
      patients: totalSesi,
      reviews: (rating * 20).round(),
      availableToday: online,
    );
  }

  static String _formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class AppointmentSession {
  final Professional professional;
  final String day;
  final String time;
  final String? consultationId;

  AppointmentSession({
    required this.professional,
    required this.day,
    required this.time,
    this.consultationId,
  });
}

class ProfessionalStore {
  static final List<Professional> professionals = [
    Professional(
      name: 'dr. Tirta M. Hudhi, Sp. KJ',
      title: 'Psikiater',
      profession: 'Dokter',
      category: 'Dokter',
      price: 'Rp 50.000/sesi',
      description:
          'dr. Tirta Mandira Hudhi lulus Sarjana Kedokteran dari Universitas Gadjah Mada (UGM) pada tahun 2013 dan menjalani sumpah dokter pada tahun 2015. Terbaru, dr. Tirta lulus Magister Administrasi Bisnis (MBA) dari Sekolah Bisnis dan Manajemen Institut Teknologi Bandung (SBM ITB) pada April 2024 dengan predikat cum laude.',
      experienceYears: 11,
      patients: 100,
      reviews: 120,
      availableToday: true,
      isFavorite: true,
    ),
    Professional(
      name: 'dr. Gia Pratama, Sp. KJ',
      title: 'Psikiater',
      profession: 'Dokter',
      category: 'Dokter',
      price: 'Rp 50.000/sesi',
      description:
          'dr. Gia Pratama adalah psikiater yang berpengalaman dalam membantu pasien mengelola kesehatan mental, kecemasan, stres, dan konsultasi psikologis.',
      experienceYears: 9,
      patients: 95,
      reviews: 118,
      availableToday: true,
    ),
    Professional(
      name: 'dr. Ayman Alatas, Sp. KJ',
      title: 'Psikiater',
      profession: 'Dokter',
      category: 'Dokter',
      price: 'Rp 50.000/sesi',
      description:
          'dr. Ayman Alatas merupakan psikiater yang fokus pada konsultasi kesehatan mental, terapi awal, dan pendampingan pasien secara profesional.',
      experienceYears: 8,
      patients: 88,
      reviews: 112,
      availableToday: false,
      isFavorite: true,
    ),
    Professional(
      name: 'dr. Ikhsanuddin Q., Sp. KJ',
      title: 'Psikiater',
      profession: 'Dokter',
      category: 'Dokter',
      price: 'Rp 50.000/sesi',
      description:
          'dr. Ikhsanuddin Q. adalah profesional kesehatan jiwa dengan pengalaman menangani berbagai kebutuhan konsultasi dan pendampingan mental.',
      experienceYears: 10,
      patients: 92,
      reviews: 119,
      availableToday: true,
      isFavorite: true,
    ),
    Professional(
      name: 'Nadia Putri, M.Psi., Psikolog',
      title: 'Psikolog Klinis',
      profession: 'Psikolog',
      category: 'Psikolog',
      price: 'Rp 45.000/sesi',
      description:
          'Nadia Putri adalah psikolog klinis yang membantu pengguna memahami emosi, stres, kecemasan, dan pengembangan diri.',
      experienceYears: 6,
      patients: 75,
      reviews: 86,
      availableToday: true,
    ),
    Professional(
      name: 'Aulia Rahma, M.Psi., Psikolog',
      title: 'Psikolog Anak',
      profession: 'Psikolog',
      category: 'Psikolog',
      price: 'Rp 45.000/sesi',
      description:
          'Aulia Rahma adalah psikolog yang berfokus pada pendampingan anak, remaja, dan keluarga.',
      experienceYears: 5,
      patients: 68,
      reviews: 79,
      availableToday: false,
    ),
  ];

  static final List<AppointmentSession> appointments = [];

  static List<Professional> get favorites {
    return professionals.where((item) => item.isFavorite).toList();
  }

  static void addProfessional(Professional professional) {
    professionals.add(professional);
  }

  static void addAppointment(AppointmentSession appointment) {
    appointments.add(appointment);
  }
}