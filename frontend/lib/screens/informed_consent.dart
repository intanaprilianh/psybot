// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'home_page.dart';

class InformedConsentPage extends ConsumerStatefulWidget {
  const InformedConsentPage({super.key});

  @override
  ConsumerState<InformedConsentPage> createState() =>
      _InformedConsentPageState();
}

class _InformedConsentPageState extends ConsumerState<InformedConsentPage> {
  bool isChecked = false;
  bool isLoading = false;

  Future<void> goToNextPage() async {
    if (!isChecked || isLoading) return;

    setState(() => isLoading = true);

    try {
      final profileService = ref.read(profileServiceProvider);
      await profileService.completeOnboarding();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan persetujuan. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22002F),
      body: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Text(
                          'Syarat dan Ketentuan\nPenggunaan Aplikasi PsyBot',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6558E8),
                            fontSize: 30,
                            height: 1.14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 20),
                        ConsentSection(
                          title: 'Pemberitahuan Penting',
                          content:
                              'Aplikasi ini bukan merupakan layanan darurat krisis, layanan medis, atau pengganti terapi tatap muka dengan tenaga profesional (Psikolog/Psikiater). Jika Anda berada dalam kondisi darurat atau memiliki pikiran untuk menyakiti diri sendiri, segera hubungi layanan darurat nasional (119) atau menuju ke rumah sakit terdekat.\n\n'
                              'Selamat datang di PsyBot. Harap membaca Syarat dan Ketentuan ini secara seksama sebelum menggunakan layanan kami. Dengan mengunduh, mendaftar, atau menggunakan Aplikasi, Anda menyatakan bahwa Anda telah membaca, memahami, dan menyetujui seluruh ketentuan ini.',
                        ),
                        SizedBox(height: 18),
                        ConsentSection(
                          title: 'Komitmen Perlindungan Data Pribadi',
                          content:
                              'Kami berkomitmen penuh untuk melindungi data pribadi Anda dengan menerapkan standar keamanan yang selaras dengan Undang-Undang No. 27 Tahun 2022 tentang Perlindungan Data Pribadi (UU PDP). Seluruh pemrosesan data dalam aplikasi ini didasarkan pada persetujuan eksplisit yang Anda berikan saat pertama kali mengakses layanan kami.\n\n'
                              'Mengingat aplikasi ini bergerak di bidang kesehatan mental, riwayat percakapan, catatan suasana hati, dan data emosional yang Anda masukkan dikategorikan sebagai Data Pribadi Spesifik atau Data Kesehatan yang kami lindungi dengan ekspresi ketat standar industri, seperti TLS/SSL, baik saat data dikirim maupun saat disimpan.\n\n'
                              'Kami mengumpulkan dan memproses data tersebut semata-mata hanya untuk menyediakan respons chatbot yang relevan dan kontekstual, serta untuk meningkatkan performa teknologi AI kami melalui proses anonimisasi yang menghapus seluruh identitas personal Anda.',
                        ),
                        SizedBox(height: 18),
                        ConsentSection(
                          title: 'Hak Subjek Data dan Ketentuan Keamanan',
                          content:
                              'Sesuai dengan amanat UU PDP, Anda memiliki hak penuh sebagai subjek data untuk mengakses, memperbarui, memperbaiki ketidakakuratan, hingga meminta penghapusan atau pemusnahan seluruh riwayat data pribadi Anda secara permanen dari sistem kami melalui menu pengaturan aplikasi atau dengan menghubungi layanan pelanggan.\n\n'
                              'Anda juga berhak menarik kembali persetujuan pemrosesan data kapan saja. Perlu diketahui, penarikan persetujuan ini dapat menyebabkan kami menghentikan sebagian atau seluruh layanan, karena data tersebut diperlukan untuk memberikan respons yang personal dan relevan.\n\n'
                              'Kami tidak pernah menjual, menyewakan, atau membagikan data pribadi Anda kepada pihak ketiga untuk kepentingan komersial maupun periklanan tanpa izin tertulis dari Anda. Namun, demi hukum dan kemanusiaan, kami berhak mengambil tindakan darurat dan membagikan informasi terbatas kepada pihak berwenang atau kontak darurat apabila sistem AI kami mendeteksi indikasi kuat adanya ancaman yang membahayakan keselamatan jiwa Anda atau orang lain.',
                        ),
                        SizedBox(height: 18),
                        ConsentSection(
                          title: 'Tanggung Jawab dan Hukum yang Berlaku',
                          content:
                              'Pengguna juga dilarang keras memasukkan data pribadi milik orang lain tanpa izin ke dalam obrolan AI atau melakukan tindakan rekayasa balik yang dapat merusak sistem.\n\n'
                              'Kami juga berhak memperbarui dokumen Syarat dan Ketentuan ini sewaktu-waktu untuk menyesuaikan dengan regulasi terbaru, di mana penggunaan aplikasi secara berkelanjutan setelah pembaruan dianggap sebagai persetujuan Anda.\n\n'
                              'Seluruh ketentuan ini diatur dan ditafsirkan berdasarkan hukum Negara Republik Indonesia, dan jika terjadi perselisihan yang tidak dapat diselesaikan secara musyawarah, maka akan diselesaikan melalui Pengadilan Negeri Surabaya.\n\n'
                              'Untuk pertanyaan atau pelaksanaan hak-hak data pribadi Anda, Anda dapat menghubungi Petugas Perlindungan Data kami melalui email support@psybot.com.',
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, -3),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: Checkbox(
                              value: isChecked,
                              activeColor: const Color(0xFF6558E8),
                              side: const BorderSide(
                                color: Color(0xFF6558E8),
                                width: 1.6,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  isChecked = value ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Saya telah membaca dan menyetujui seluruh syarat dan ketentuan',
                              style: TextStyle(
                                color: Color(0xFF444444),
                                fontSize: 14,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              isChecked && !isLoading ? goToNextPage : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8A3A95),
                            disabledBackgroundColor: const Color(0xFFD0B2D6),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white70,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            isLoading ? 'Menyimpan...' : 'Selanjutnya',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ConsentSection extends StatelessWidget {
  final String title;
  final String content;

  const ConsentSection({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8A3A95),
            fontSize: 18,
            height: 1.22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          textAlign: TextAlign.justify,
          style: const TextStyle(
            color: Color(0xFF111111),
            fontSize: 13.5,
            height: 1.48,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
