import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:vasudha/widgets/auto_text.dart';
// import 'dart:html' as html;
// import 'dart:ui_web' as ui;

class VideoModel {
  final int id;
  final String title;
  final String crop;
  final String language;
  final String youtubeId;
  final String description;
  bool isExpanded;

  VideoModel({
    required this.id,
    required this.title,
    required this.crop,
    required this.language,
    required this.youtubeId,
    required this.description,
    this.isExpanded = false,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      title: json['title'] ?? '',
      crop: json['crop_subject'] ?? '',
      language: json['language'] ?? '',
      youtubeId: YoutubePlayer.convertUrlToId(json['youtube_url'] ?? '') ?? '',
      description: json['description'] ?? '',
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;

  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: true,
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: const Text("Video Player")),
          body: Center(child: player),
        );
      },
    );
  }
}

class SearchCropVideosScreen extends StatefulWidget {
  const SearchCropVideosScreen({super.key});

  @override
  State<SearchCropVideosScreen> createState() => _SearchCropVideosScreenState();
}

class _SearchCropVideosScreenState extends State<SearchCropVideosScreen> {
  String? selectedCrop;
  String? selectedLanguage;

  List<String> crops = [];
  List<String> languages = [];

  final ScrollController _scrollController = ScrollController();

  bool isLoading = false;
  bool isLoadingMore = false;

  final List<VideoModel> videos = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);

    final res = await ApiService.getCropVideos();

    if (res['ok'] == true) {
      crops = List<String>.from(res['crops'] ?? []);
      languages =
          (res['languages'] as List?)
              ?.map((e) => e['name'].toString())
              .toList() ??
          [];

      videos.clear();
      videos.addAll(
        (res['videos'] as List).map((e) => VideoModel.fromJson(e)).toList(),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> _searchVideos() async {
    setState(() {
      isLoading = true;
      videos.clear();
    });

    final res = await ApiService.getCropVideos(
      cropSubject: selectedCrop,
      language: selectedLanguage,
    );

    if (res['ok'] == true) {
      videos.addAll(
        (res['videos'] as List).map((e) => VideoModel.fromJson(e)).toList(),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const AutoText('Search Crop Videos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔍 Search Filters (UNCHANGED)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AutoText(
                      'Search Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    isMobile
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _filterFieldsMobile(),
                          )
                        : Row(children: _filterFieldsDesktop()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const AutoText(
              'Videos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (videos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: AutoText('No videos found')),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: videos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isMobile ? 0.75 : 0.8, // 🔥 FIX
                ),
                itemBuilder: (context, index) {
                  return VideoCard(video: videos[index]);
                },
              ),

            if (isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _filterFieldsMobile() {
    return [
      _dropdown(
        label: 'Crops',
        value: selectedCrop,
        items: crops,
        onChanged: (val) => setState(() => selectedCrop = val),
      ),
      const SizedBox(height: 12),
      _dropdown(
        label: 'Language',
        value: selectedLanguage,
        items: languages,
        onChanged: (val) => setState(() => selectedLanguage = val),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 48,
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          onPressed: _searchVideos,
          child: const AutoText('Search'),
        ),
      ),
    ];
  }

  List<Widget> _filterFieldsDesktop() {
    return [
      Flexible(
        child: _dropdown(
          label: 'Crops',
          value: selectedCrop,
          items: crops,
          onChanged: (val) => setState(() => selectedCrop = val),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: _dropdown(
          label: 'Language',
          value: selectedLanguage,
          items: languages,
          onChanged: (val) => setState(() => selectedLanguage = val),
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          onPressed: _searchVideos,
          child: const AutoText('Search'),
        ),
      ),
    ];
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoText(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          hint: const AutoText('-- Select --'),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: AutoText(e)))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _videoCard(VideoModel video) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ✅ FIX: YoutubePlayer MUST have bounded height (Web safe)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: UniversalYoutubePlayer(videoId: video.youtubeId),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoText(
                  video.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                AutoText('Crop: ${video.crop}'),
                AutoText('Language: ${video.language}'),
                const SizedBox(height: 6),

                if (!video.isExpanded)
                  AutoText(
                    video.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  )
                else
                  SizedBox(
                    height: 120, // 👈 fixed height to avoid overflow
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: AutoText(
                        video.description,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      video.isExpanded = !video.isExpanded;
                    });
                  },
                  child: AutoText(
                    video.isExpanded ? 'Read Less' : 'Read More',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoCard extends StatefulWidget {
  final VideoModel video;

  const VideoCard({super.key, required this.video});

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.video.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🎥 VIDEO (WILL NOT REBUILD)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: UniversalYoutubePlayer(
              key: ValueKey(video.youtubeId), // 🔥 VERY IMPORTANT
              videoId: video.youtubeId,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoText(
                  video.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                AutoText('Crop: ${video.crop}'),
                AutoText('Language: ${video.language}'),
                const SizedBox(height: 6),

                if (!isExpanded)
                  AutoText(
                    video.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: SingleChildScrollView(
                      child: AutoText(
                        video.description,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  child: AutoText(
                    isExpanded ? 'Read Less' : 'Read More',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UniversalYoutubePlayer extends StatelessWidget {
  final String videoId;

  const UniversalYoutubePlayer({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(videoId: videoId),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            "https://img.youtube.com/vi/$videoId/0.jpg",
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          const Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
        ],
      ),
    );
  }
}
