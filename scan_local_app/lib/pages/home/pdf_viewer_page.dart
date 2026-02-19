import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:pdfrx/pdfrx.dart';

class PDFViewerPage extends StatefulWidget {
  final String filePath;

  const PDFViewerPage({super.key, required this.filePath});

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();

  PdfTextSearcher? _textSearcher;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _hasMatches = false;

  void _update() {
    if (mounted) {
      setState(() {
        _hasMatches = _textSearcher?.matches.isNotEmpty ?? false;
      });
    }
  }

  void _performSearch(String query) {
      _textSearcher?.startTextSearch(query, caseInsensitive: true);
  }

  void _clearSearch() {
    _searchController.clear();
    _textSearcher?.startTextSearch('');
    setState(() {
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _textSearcher?.removeListener(_update);
    _textSearcher?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search text...',
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.search,
                onChanged: _performSearch,
              )
            : Text(path.basename(widget.filePath)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              if (_isSearching) {
                _clearSearch();
              } else {
                setState(() => _isSearching = true);
              }
            },
          ),

          if (_isSearching && _hasMatches) ...[
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: () => _textSearcher?.goToPrevMatch(),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => _textSearcher?.goToNextMatch(),
            ),
          ],

          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => SharePlus.instance.share(
                ShareParams(files: [XFile(widget.filePath)]),
              ),
            ),
        ],
      ),
      body: PdfViewer.file(
        widget.filePath,
        controller: _pdfViewerController,
        params: PdfViewerParams(
          onViewerReady: (document, controller) {
            if (_textSearcher == null) {
              _textSearcher = PdfTextSearcher(_pdfViewerController)
                ..addListener(_update);
              _update();
            }
          },
          pagePaintCallbacks: [
            (canvas, pageRect, page) {
              _textSearcher?.pageTextMatchPaintCallback(canvas, pageRect, page);
            },
          ],
        ),
      ),
    );
  }
}
