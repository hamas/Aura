import 'package:equatable/equatable.dart';

class ScrapedStreamItem extends Equatable {
  final String id;
  final String title;
  final String name;
  final String? url;
  final String? infoHash;
  final int fileIndex;
  final String resolution;
  final bool isHdr;
  final bool isDolbyVision;
  final bool isDolbyAtmos;
  final bool isDtsHd;
  final bool isRemux;
  final double sizeGb;
  final int seeders;
  final bool isCached;

  const ScrapedStreamItem({
    required this.id,
    required this.title,
    required this.name,
    this.url,
    this.infoHash,
    this.fileIndex = 0,
    this.resolution = '1080p',
    this.isHdr = false,
    this.isDolbyVision = false,
    this.isDolbyAtmos = false,
    this.isDtsHd = false,
    this.isRemux = false,
    this.sizeGb = 0.0,
    this.seeders = 0,
    this.isCached = true,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        name,
        url,
        infoHash,
        fileIndex,
        resolution,
        isHdr,
        isDolbyVision,
        isDolbyAtmos,
        isDtsHd,
        isRemux,
        sizeGb,
        seeders,
        isCached,
      ];
}
