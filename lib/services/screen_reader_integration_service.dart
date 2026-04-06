import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'dart:async';
import './ai_voice_navigation_service.dart';

/// ==================== SCREEN READER INTEGRATION SERVICE ====================
///
/// ADVANCED SCREEN READER SYSTEM
/// Complete screen reader integration:
/// - Widget traversal & reading
/// - Focus management
/// - Semantic labels
/// - Reading order control
/// - Gesture navigation
/// - Custom reading patterns
/// - Context-aware reading
/// - Interactive element detection
///
/// 24-HOUR MARATHON - PHASE 6 (HOUR 22)
/// ================================================================

// ==================== READABLE ELEMENT ====================

enum ElementType {
  button,
  textField,
  label,
  image,
  list,
  card,
  header,
  link,
  checkbox,
  switch_,
  slider,
  custom,
}

class ReadableElement {
  final String id;
  final ElementType type;
  final String label;
  final String? hint;
  final String? value;
  final bool isEnabled;
  final bool isFocusable;
  final int order;
  final Map<String, dynamic>? metadata;

  ReadableElement({
    required this.id,
    required this.type,
    required this.label,
    this.hint,
    this.value,
    this.isEnabled = true,
    this.isFocusable = true,
    this.order = 0,
    this.metadata,
  });

  String getReadableText() {
    final buffer = StringBuffer();

    // Type prefix
    switch (type) {
      case ElementType.button:
        buffer.write('Button: ');
        break;
      case ElementType.textField:
        buffer.write('Text field: ');
        break;
      case ElementType.checkbox:
        buffer.write('Checkbox: ');
        break;
      case ElementType.switch_:
        buffer.write('Switch: ');
        break;
      case ElementType.slider:
        buffer.write('Slider: ');
        break;
      case ElementType.header:
        buffer.write('Heading: ');
        break;
      case ElementType.link:
        buffer.write('Link: ');
        break;
      default:
        break;
    }

    // Label
    buffer.write(label);

    // Value
    if (value != null && value!.isNotEmpty) {
      buffer.write('. Current value: $value');
    }

    // State
    if (type == ElementType.checkbox || type == ElementType.switch_) {
      final checked = value == 'true' || value == '1';
      buffer.write(checked ? '. Checked' : '. Unchecked');
    }

    // Enabled state
    if (!isEnabled) {
      buffer.write('. Disabled');
    }

    // Hint
    if (hint != null && hint!.isNotEmpty) {
      buffer.write('. $hint');
    }

    return buffer.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'label': label,
      'hint': hint,
      'value': value,
      'isEnabled': isEnabled,
      'isFocusable': isFocusable,
      'order': order,
      'metadata': metadata,
    };
  }
}

// ==================== READING MODE ====================

enum ReadingMode {
  sequential, // Read elements in order
  headingsOnly, // Read only headers
  interactive, // Read only interactive elements
  all, // Read everything
  custom, // Custom filter
}

// ==================== GESTURE NAVIGATION ====================

enum NavigationGesture {
  swipeRight, // Next element
  swipeLeft, // Previous element
  swipeDown, // Next section
  swipeUp, // Previous section
  doubleTap, // Activate element
  twoFingerTap, // Stop reading
  threeFingerTap, // Read from top
}

// ==================== SCREEN READER INTEGRATION SERVICE ====================

class ScreenReaderIntegrationService {
  final AIVoiceNavigationService _voiceService;

  // State
  bool _isInitialized = false;
  bool _isEnabled = false;
  bool _isReading = false;

  ReadingMode _readingMode = ReadingMode.sequential;
  int _currentElementIndex = 0;
  List<ReadableElement> _currentElements = [];

  // Focus management
  FocusNode? _currentFocusNode;
  final Map<String, FocusNode> _focusNodes = {};

  // Callbacks
  Function(ReadableElement element)? onElementFocused;
  Function(ReadableElement element)? onElementActivated;
  Function(String message)? onLog;
  Function(String error)? onError;

  // Getters
  bool isInitialized() => _isInitialized;
  bool isEnabled() => _isEnabled;
  bool isReading() => _isReading;
  ReadingMode getReadingMode() => _readingMode;
  int getCurrentIndex() => _currentElementIndex;
  List<ReadableElement> getCurrentElements() => List.unmodifiable(_currentElements);

  ScreenReaderIntegrationService(this._voiceService);

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint(' Initializing Screen Reader Integration Service...');

      // Ensure voice service is initialized
      if (!_voiceService.isInitialized()) {
        await _voiceService.initialize();
      }

      _isInitialized = true;
      debugPrint(' Screen Reader Integration Service initialized');
    } catch (e) {
      debugPrint(' Screen Reader initialization error: $e');
      onError?.call('Failed to initialize screen reader: $e');
      rethrow;
    }
  }

  void dispose() {
    stopReading();
    _currentElements.clear();
    _focusNodes.clear();
    _isInitialized = false;
    debugPrint(' Screen Reader Integration Service disposed');
  }

  // ==================== ENABLE/DISABLE ====================

  Future<void> enable() async {
    _isEnabled = true;
    onLog?.call('Screen reader enabled');
    await _voiceService.speak('Screen reader enabled');
    debugPrint(' Screen reader enabled');
  }

  Future<void> disable() async {
    _isEnabled = false;
    await stopReading();
    onLog?.call('Screen reader disabled');
    debugPrint(' Screen reader disabled');
  }

  // ==================== ELEMENT REGISTRATION ====================

  /// Register elements on current screen
  void registerElements(List<ReadableElement> elements) {
    _currentElements = List.from(elements)
      ..sort((a, b) => a.order.compareTo(b.order));
    _currentElementIndex = 0;

    debugPrint(' Registered ${elements.length} readable elements');
    onLog?.call('Screen has ${elements.length} interactive elements');
  }

  /// Add single element
  void addElement(ReadableElement element) {
    _currentElements.add(element);
    _currentElements.sort((a, b) => a.order.compareTo(b.order));
    debugPrint(' Added element: ${element.label}');
  }

  /// Remove element
  void removeElement(String elementId) {
    _currentElements.removeWhere((e) => e.id == elementId);
    debugPrint(' Removed element: $elementId');
  }

  /// Clear all elements
  void clearElements() {
    _currentElements.clear();
    _currentElementIndex = 0;
    debugPrint(' Cleared all elements');
  }

  // ==================== READING ====================

  /// Read all elements on screen
  Future<void> readScreen() async {
    if (!_isEnabled || _currentElements.isEmpty) return;

    _isReading = true;
    _currentElementIndex = 0;

    onLog?.call('Reading screen...');
    debugPrint(' Reading screen with ${_currentElements.length} elements');

    // Announce screen context
    await _voiceService.announceCurrentScreen();

    // Read all elements
    for (int i = 0; i < _currentElements.length; i++) {
      if (!_isReading) break;

      _currentElementIndex = i;
      await readCurrentElement();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isReading = false;
    onLog?.call('Finished reading screen');
    debugPrint(' Finished reading screen');
  }

  /// Read current element
  Future<void> readCurrentElement() async {
    if (!_isEnabled || _currentElements.isEmpty) return;

    if (_currentElementIndex >= 0 && _currentElementIndex < _currentElements.length) {
      final element = _currentElements[_currentElementIndex];
      await readElement(element);
    }
  }

  /// Read specific element
  Future<void> readElement(ReadableElement element) async {
    if (!_isEnabled) return;

    final text = element.getReadableText();
    await _voiceService.speak(text);

    onElementFocused?.call(element);
    debugPrint(' Read element: ${element.label}');
  }

  /// Stop reading
  Future<void> stopReading() async {
    _isReading = false;
    await _voiceService.stopSpeaking();
    onLog?.call('Stopped reading');
    debugPrint(' Stopped reading');
  }

  // ==================== NAVIGATION ====================

  /// Navigate to next element
  Future<void> nextElement() async {
    if (!_isEnabled || _currentElements.isEmpty) return;

    _currentElementIndex = (_currentElementIndex + 1) % _currentElements.length;
    await readCurrentElement();
  }

  /// Navigate to previous element
  Future<void> previousElement() async {
    if (!_isEnabled || _currentElements.isEmpty) return;

    _currentElementIndex = (_currentElementIndex - 1 + _currentElements.length) % _currentElements.length;
    await readCurrentElement();
  }

  /// Navigate to first element
  Future<void> firstElement() async {
    if (!_isEnabled || _currentElements.isEmpty) return;

    _currentElementIndex = 0;
    await readCurrentElement();
  }

  /// Navigate to last element
  Future<void> lastElement() async {
    if (!_isEnabled || _currentElements.isEmpty) return;

    _currentElementIndex = _currentElements.length - 1;
    await readCurrentElement();
  }

  /// Navigate to element by ID
  Future<void> navigateToElement(String elementId) async {
    if (!_isEnabled) return;

    final index = _currentElements.indexWhere((e) => e.id == elementId);
    if (index != -1) {
      _currentElementIndex = index;
      await readCurrentElement();
    }
  }

  // ==================== READING MODES ====================

  /// Set reading mode
  void setReadingMode(ReadingMode mode) {
    _readingMode = mode;
    debugPrint(' Reading mode set to: ${mode.toString()}');
    onLog?.call('Reading mode: ${mode.toString().split('.').last}');
  }

  /// Get elements based on reading mode
  List<ReadableElement> _getFilteredElements() {
    switch (_readingMode) {
      case ReadingMode.sequential:
        return _currentElements;

      case ReadingMode.headingsOnly:
        return _currentElements.where((e) => e.type == ElementType.header).toList();

      case ReadingMode.interactive:
        return _currentElements.where((e) =>
        e.type == ElementType.button ||
            e.type == ElementType.textField ||
            e.type == ElementType.checkbox ||
            e.type == ElementType.switch_ ||
            e.type == ElementType.slider ||
            e.type == ElementType.link
        ).toList();

      case ReadingMode.all:
        return _currentElements;

      case ReadingMode.custom:
        return _currentElements;
    }
  }

  // ==================== GESTURE HANDLING ====================

  /// Handle navigation gesture
  Future<void> handleGesture(NavigationGesture gesture) async {
    if (!_isEnabled) return;

    debugPrint(' Gesture: ${gesture.toString()}');

    switch (gesture) {
      case NavigationGesture.swipeRight:
        await nextElement();
        break;

      case NavigationGesture.swipeLeft:
        await previousElement();
        break;

      case NavigationGesture.swipeDown:
        await _nextSection();
        break;

      case NavigationGesture.swipeUp:
        await _previousSection();
        break;

      case NavigationGesture.doubleTap:
        await activateCurrentElement();
        break;

      case NavigationGesture.twoFingerTap:
        await stopReading();
        break;

      case NavigationGesture.threeFingerTap:
        await readScreen();
        break;
    }
  }

  Future<void> _nextSection() async {
    // Find next header
    final headers = _currentElements.where((e) => e.type == ElementType.header).toList();
    if (headers.isEmpty) return;

    final currentHeader = headers.where((h) {
      final index = _currentElements.indexOf(h);
      return index > _currentElementIndex;
    }).toList();

    if (currentHeader.isNotEmpty) {
      _currentElementIndex = _currentElements.indexOf(currentHeader.first);
      await readCurrentElement();
    }
  }

  Future<void> _previousSection() async {
    // Find previous header
    final headers = _currentElements.where((e) => e.type == ElementType.header).toList();
    if (headers.isEmpty) return;

    final currentHeader = headers.reversed.where((h) {
      final index = _currentElements.indexOf(h);
      return index < _currentElementIndex;
    }).toList();

    if (currentHeader.isNotEmpty) {
      _currentElementIndex = _currentElements.indexOf(currentHeader.first);
      await readCurrentElement();
    }
  }

  // ==================== ELEMENT ACTIVATION ====================

  /// Activate current element
  Future<void> activateCurrentElement() async {
    if (!_isEnabled || _currentElements.isEmpty) return;

    if (_currentElementIndex >= 0 && _currentElementIndex < _currentElements.length) {
      final element = _currentElements[_currentElementIndex];
      await activateElement(element);
    }
  }

  /// Activate specific element
  Future<void> activateElement(ReadableElement element) async {
    if (!element.isEnabled) {
      await _voiceService.speak('This ${element.type.toString().split('.').last} is disabled');
      return;
    }

    onElementActivated?.call(element);
    await _voiceService.speak('Activated ${element.label}');
    debugPrint(' Activated element: ${element.label}');
  }

  // ==================== FOCUS MANAGEMENT ====================

  /// Register focus node for element
  void registerFocusNode(String elementId, FocusNode node) {
    _focusNodes[elementId] = node;
  }

  /// Focus on current element
  void focusCurrentElement() {
    if (_currentElements.isEmpty) return;

    final element = _currentElements[_currentElementIndex];
    final focusNode = _focusNodes[element.id];

    if (focusNode != null) {
      focusNode.requestFocus();
      _currentFocusNode = focusNode;
    }
  }

  /// Handle focus change
  Future<void> onFocusChanged(String elementId) async {
    final index = _currentElements.indexWhere((e) => e.id == elementId);
    if (index != -1) {
      _currentElementIndex = index;
      await readCurrentElement();
    }
  }

  // ==================== SEMANTIC HELPERS ====================

  /// Get semantic properties for widget
  SemanticsProperties getSemanticsProperties(ReadableElement element) {
    return SemanticsProperties(
      label: element.label,
      hint: element.hint,
      value: element.value,
      enabled: element.isEnabled,
      button: element.type == ElementType.button,
      textField: element.type == ElementType.textField,
      link: element.type == ElementType.link,
      header: element.type == ElementType.header,
      image: element.type == ElementType.image,
      slider: element.type == ElementType.slider,
      checked: element.type == ElementType.checkbox && element.value == 'true',
      toggled: element.type == ElementType.switch_ && element.value == 'true',
    );
  }

  /// Wrap widget with semantics
  Widget wrapWithSemantics(Widget child, ReadableElement element) {
    return Semantics(
      label: element.label,
      hint: element.hint,
      value: element.value,
      enabled: element.isEnabled,
      button: element.type == ElementType.button,
      textField: element.type == ElementType.textField,
      link: element.type == ElementType.link,
      header: element.type == ElementType.header,
      image: element.type == ElementType.image,
      onTap: element.type == ElementType.button || element.type == ElementType.link
          ? () => activateElement(element)
          : null,
      child: child,
    );
  }

  // ==================== SCREEN ANALYSIS ====================

  /// Analyze screen structure
  Map<String, dynamic> analyzeScreen() {
    final analysis = {
      'totalElements': _currentElements.length,
      'interactiveElements': _currentElements.where((e) =>
      e.type == ElementType.button ||
          e.type == ElementType.textField ||
          e.type == ElementType.link
      ).length,
      'headers': _currentElements.where((e) => e.type == ElementType.header).length,
      'images': _currentElements.where((e) => e.type == ElementType.image).length,
      'textFields': _currentElements.where((e) => e.type == ElementType.textField).length,
      'buttons': _currentElements.where((e) => e.type == ElementType.button).length,
      'disabledElements': _currentElements.where((e) => !e.isEnabled).length,
      'elementTypes': _getElementTypeCount(),
    };

    debugPrint(' Screen analysis: $analysis');
    return analysis;
  }

  Map<String, int> _getElementTypeCount() {
    final counts = <String, int>{};
    for (final element in _currentElements) {
      final type = element.type.toString().split('.').last;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  /// Get reading summary
  String getReadingSummary() {
    final analysis = analyzeScreen();
    return 'Screen contains ${analysis['totalElements']} elements. '
        '${analysis['interactiveElements']} are interactive. '
        '${analysis['headers']} headers found.';
  }

  // ==================== ANNOUNCEMENTS ====================

  /// Announce screen loaded
  Future<void> announceScreenLoaded(String screenName) async {
    if (!_isEnabled) return;

    await _voiceService.speak('$screenName loaded. ${getReadingSummary()}');
  }

  /// Announce progress
  Future<void> announceProgress(String message) async {
    if (!_isEnabled) return;

    await _voiceService.speak(message);
  }

  /// Announce error
  Future<void> announceError(String error) async {
    if (!_isEnabled) return;

    await _voiceService.speak('Error: $error');
  }

  // ==================== HELPER METHODS ====================

  /// Get current element
  ReadableElement? getCurrentElement() {
    if (_currentElements.isEmpty || _currentElementIndex < 0 || _currentElementIndex >= _currentElements.length) {
      return null;
    }
    return _currentElements[_currentElementIndex];
  }

  /// Find element by label
  ReadableElement? findElementByLabel(String label) {
    try {
      return _currentElements.firstWhere(
            (e) => e.label.toLowerCase().contains(label.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  /// Find elements by type
  List<ReadableElement> findElementsByType(ElementType type) {
    return _currentElements.where((e) => e.type == type).toList();
  }

  // ==================== PRESET ELEMENT BUILDERS ====================

  /// Create button element
  static ReadableElement createButton(
      String id,
      String label, {
        String? hint,
        bool isEnabled = true,
        int order = 0,
      }) {
    return ReadableElement(
      id: id,
      type: ElementType.button,
      label: label,
      hint: hint,
      isEnabled: isEnabled,
      order: order,
    );
  }

  /// Create text field element
  static ReadableElement createTextField(
      String id,
      String label, {
        String? value,
        String? hint,
        bool isEnabled = true,
        int order = 0,
      }) {
    return ReadableElement(
      id: id,
      type: ElementType.textField,
      label: label,
      value: value,
      hint: hint,
      isEnabled: isEnabled,
      order: order,
    );
  }

  /// Create header element
  static ReadableElement createHeader(
      String id,
      String label, {
        int order = 0,
      }) {
    return ReadableElement(
      id: id,
      type: ElementType.header,
      label: label,
      order: order,
    );
  }

  /// Create switch element
  static ReadableElement createSwitch(
      String id,
      String label, {
        required bool value,
        String? hint,
        bool isEnabled = true,
        int order = 0,
      }) {
    return ReadableElement(
      id: id,
      type: ElementType.switch_,
      label: label,
      value: value.toString(),
      hint: hint,
      isEnabled: isEnabled,
      order: order,
    );
  }

  /// Create checkbox element
  static ReadableElement createCheckbox(
      String id,
      String label, {
        required bool value,
        String? hint,
        bool isEnabled = true,
        int order = 0,
      }) {
    return ReadableElement(
      id: id,
      type: ElementType.checkbox,
      label: label,
      value: value.toString(),
      hint: hint,
      isEnabled: isEnabled,
      order: order,
    );
  }
}