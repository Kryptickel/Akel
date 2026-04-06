import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
const OnboardingScreen({Key? key}) : super(key: key);

@override
State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
final PageController _controller = PageController();
int currentPage = 0;

final List<Map<String, String>> onboardingData = [
{
"image": "assets/images/onboarding_3.png",
"title": "Accessibility & Vision Support",
"description": "Enhance safety and awareness with smart accessibility tools."
},
{
"image": "assets/images/onboarding_2.png",
"title": "Cognitive & Memory Support",
"description": "AI tools that keep you alert and informed during emergencies."
},
{
"image": "assets/images/onboarding_1.png",
"title": "Emergency Panic Button",
"description": "Instantly activate alerts, share location, and connect to safety."
},
];

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.black,
body: SafeArea(
child: Column(
children: [
Expanded(
flex: 4,
child: PageView.builder(
controller: _controller,
onPageChanged: (index) {
setState(() {
currentPage = index;
});
},
itemCount: onboardingData.length,
itemBuilder: (context, index) => Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Image.asset(
onboardingData[index]["image"]!,
height: 280,
width: 280,
fit: BoxFit.contain,
),
const SizedBox(height: 25),
Text(
onboardingData[index]["title"]!,
style: const TextStyle(
color: Colors.white,
fontSize: 22,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 12),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 24),
child: Text(
onboardingData[index]["description"]!,
textAlign: TextAlign.center,
style: const TextStyle(
color: Colors.white70,
fontSize: 16,
),
),
),
],
),
),
),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: List.generate(
onboardingData.length,
(index) => AnimatedContainer(
duration: const Duration(milliseconds: 300),
margin: const EdgeInsets.only(right: 8),
height: 8,
width: currentPage == index ? 24 : 8,
decoration: BoxDecoration(
color: currentPage == index ? Colors.red : Colors.white30,
borderRadius: BorderRadius.circular(8),
),
),
),
),
const SizedBox(height: 25),
ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
onPressed: () {
if (currentPage == onboardingData.length - 1) {
// Navigate to main screen or login
} else {
_controller.nextPage(
duration: const Duration(milliseconds: 400),
curve: Curves.easeInOut,
);
}
},
child: Text(
currentPage == onboardingData.length - 1 ? "Get Started" : "Next",
style: const TextStyle(color: Colors.white, fontSize: 18),
),
),
const SizedBox(height: 40),
],
),
),
);
}
}

