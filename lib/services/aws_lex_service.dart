import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/themes/utils/api_keys.dart';
import '../models/ai_message.dart';

class AWSLexService {
  static final AWSLexService _instance = AWSLexService._internal();
  factory AWSLexService() => _instance;
  AWSLexService._internal();

  String? _sessionId;

  // Initialize session
  void initSession(String userId) {
    _sessionId = 'session-$userId-${DateTime.now().millisecondsSinceEpoch}';
    print(' AWS Lex session initialized: $_sessionId');
  }

  // Send message to AWS Lex
  Future<AIMessage> sendMessage(String text) async {
    try {
      // If test mode is enabled, use mock responses
      if (ApiKeys.enableTestMode) {
        return _getMockResponse(text);
      }

      // In production, this would call actual AWS Lex API
      // For now, we'll use enhanced mock responses that simulate real medical AI
      return _getEnhancedMockResponse(text);

      /* PRODUCTION CODE (uncomment when AWS is configured):

 final endpoint = ApiKeys.lexEndpoint;
 final botId = ApiKeys.lexBotId;
 final botAliasId = ApiKeys.lexBotAliasId;
 final localeId = ApiKeys.lexLocaleId;

 final url = Uri.parse(
 '$endpoint/bots/$botId/botAliases/$botAliasId/botLocales/$localeId/sessions/$_sessionId/text'
 );

 final response = await http.post(
 url,
 headers: {
 'Content-Type': 'application/json',
 'Authorization': 'Bearer ${ApiKeys.awsAccessKeyId}',
 },
 body: jsonEncode({
 'text': text,
 'sessionId': _sessionId,
 }),
 );

 if (response.statusCode == 200) {
 final data = jsonDecode(response.body);
 final aiResponse = data['messages'][0]['content'];

 return AIMessage.ai(
 aiResponse,
 metadata: {
 'intent': data['sessionState']['intent']['name'],
 'confidence': data['sessionState']['intent']['confirmationState'],
 },
 );
 } else {
 throw Exception('Lex API error: ${response.statusCode}');
 }
 */

    } catch (e) {
      print('Error sending message to Lex: $e');
      return AIMessage.error(
        'Sorry, I\'m having trouble connecting right now. Please try again.',
      );
    }
  }

  // Enhanced mock response for realistic medical AI simulation
  AIMessage _getEnhancedMockResponse(String text) {
    final lowerText = text.toLowerCase();

    // ==================== GREETINGS ====================
    if (lowerText.contains('hello') ||
        lowerText.contains('hi') ||
        lowerText.contains('hey') ||
        lowerText.contains('good morning') ||
        lowerText.contains('good afternoon') ||
        lowerText.contains('good evening')) {
      return AIMessage.ai(
        "Hello! I'm Doctor Annie, your AI health assistant. I'm here to help with:\n\n"
            "• Symptom checking\n"
            "• First aid guidance\n"
            "• Medication information\n"
            "• Finding nearby hospitals\n"
            "• General health questions\n\n"
            "How can I help you today?",
        metadata: {'intent': 'greeting', 'recommend_hospital': false},
      );
    }

    // ==================== CHEST PAIN - CRITICAL EMERGENCY ====================
    if (lowerText.contains('chest pain') ||
        lowerText.contains('heart pain') ||
        lowerText.contains('chest hurt') ||
        lowerText.contains('heart attack')) {
      return AIMessage.ai(
        " **CHEST PAIN IS A MEDICAL EMERGENCY**\n\n"
            "If you're experiencing chest pain, you should:\n\n"
            " **CALL 911 IMMEDIATELY if you have:**\n"
            "• Pressure, tightness, or squeezing in chest\n"
            "• Pain spreading to jaw, neck, arms, or back\n"
            "• Shortness of breath\n"
            "• Nausea, lightheadedness, cold sweats\n"
            "• Sudden severe chest pain\n\n"
            "**While waiting for help:**\n"
            "1. Sit down and try to stay calm\n"
            "2. Loosen tight clothing\n"
            "3. If you have aspirin and no allergies, chew one (325mg)\n"
            "4. Do NOT drive yourself to hospital\n\n"
            " **You can also use the Fire Emergency button in this app** to alert emergency services.\n\n"
            "**I can help you find the nearest emergency room right now.**\n\n"
            "Is this pain severe or sudden?",
        metadata: {'intent': 'emergency', 'symptom': 'chest_pain', 'recommend_hospital': true},
      );
    }

    // ==================== BREATHING PROBLEMS - EMERGENCY ====================
    if (lowerText.contains('can\'t breathe') ||
        lowerText.contains('difficulty breathing') ||
        lowerText.contains('shortness of breath') ||
        lowerText.contains('breathing hard') ||
        lowerText.contains('gasping')) {
      return AIMessage.ai(
        " **DIFFICULTY BREATHING IS A MEDICAL EMERGENCY**\n\n"
            "**CALL 911 IMMEDIATELY if you have:**\n"
            "• Severe shortness of breath\n"
            "• Chest pain with breathing difficulty\n"
            "• Blue lips or fingernails\n"
            "• Confusion or extreme drowsiness\n"
            "• Unable to speak in full sentences\n\n"
            "**While waiting for help:**\n"
            "1. Sit upright (don't lie down)\n"
            "2. Try to stay calm - panic makes it worse\n"
            "3. Loosen tight clothing\n"
            "4. If you have an inhaler, use it\n\n"
            "**I can help you find the nearest emergency room immediately.**\n\n"
            "Are you able to breathe at all?",
        metadata: {'intent': 'emergency', 'symptom': 'breathing', 'recommend_hospital': true},
      );
    }

    // ==================== SEVERE BLEEDING - EMERGENCY ====================
    if (lowerText.contains('bleeding') ||
        lowerText.contains('blood') ||
        lowerText.contains('cut deep')) {
      return AIMessage.ai(
        " **SEVERE BLEEDING REQUIRES IMMEDIATE ACTION**\n\n"
            "**CALL 911 if:**\n"
            "• Bleeding won't stop after 10 minutes of pressure\n"
            "• Blood spurting or flowing continuously\n"
            "• Deep wound\n"
            "• Large amount of blood loss\n\n"
            "**For minor cuts:**\n"
            "1. Apply direct pressure with clean cloth\n"
            "2. Keep pressure for 10-15 minutes\n"
            "3. Don't peek - this disrupts clotting\n"
            "4. Elevate the wound above heart if possible\n"
            "5. Once stopped, clean and bandage\n\n"
            "**Seek urgent care if:**\n"
            "• Cut is deep or gaping\n"
            "• Edges won't stay together\n"
            "• On face or joint\n"
            "• Caused by dirty or rusty object\n\n"
            "How severe is the bleeding?",
        metadata: {'intent': 'first_aid', 'symptom': 'bleeding', 'recommend_hospital': true},
      );
    }

    // ==================== HEADACHE ====================
    if (lowerText.contains('headache') ||
        lowerText.contains('head hurts') ||
        lowerText.contains('head pain') ||
        lowerText.contains('migraine')) {
      return AIMessage.ai(
        "I understand you're experiencing a headache. Let me help you assess this:\n\n"
            "**Common Causes:**\n"
            "• Tension or stress\n"
            "• Dehydration\n"
            "• Eye strain\n"
            "• Sinus pressure\n"
            "• Lack of sleep\n"
            "• Caffeine withdrawal\n\n"
            "**What You Can Do:**\n"
            "1. Drink water (dehydration is very common)\n"
            "2. Rest in a quiet, dark room\n"
            "3. Apply cold compress to forehead\n"
            "4. Take over-the-counter pain reliever (if appropriate)\n"
            "5. Massage temples and neck\n\n"
            "** Seek immediate medical care if:**\n"
            "• Sudden, severe headache (worst of your life)\n"
            "• Headache with fever, stiff neck, confusion\n"
            "• Vision changes or difficulty speaking\n"
            "• Headache after head injury\n"
            "• Thunderclap headache (peaks in seconds)\n\n"
            "If you have any of these warning signs, **I can help you find the nearest hospital or urgent care center immediately.**\n\n"
            "How long have you had this headache? Is it severe?",
        metadata: {'intent': 'symptom_check', 'symptom': 'headache', 'recommend_hospital': false},
      );
    }

    // ==================== FEVER ====================
    if (lowerText.contains('fever') ||
        lowerText.contains('temperature') ||
        lowerText.contains('hot') && lowerText.contains('feel')) {
      return AIMessage.ai(
        "A fever is your body's way of fighting infection. Here's what you should know:\n\n"
            "**Fever Guidelines:**\n"
            "• Normal: 97°F - 99°F (36.1°C - 37.2°C)\n"
            "• Low-grade fever: 99°F - 100.4°F\n"
            "• Fever: Above 100.4°F (38°C)\n"
            "• High fever: Above 103°F (39.4°C)\n\n"
            "**Home Care:**\n"
            "1. Stay hydrated (water, broth, electrolyte drinks)\n"
            "2. Rest and avoid strenuous activity\n"
            "3. Take acetaminophen or ibuprofen (if appropriate)\n"
            "4. Dress in light clothing\n"
            "5. Use lukewarm compress (not cold)\n"
            "6. Take a lukewarm bath\n\n"
            "** Seek urgent medical care if:**\n"
            "• Fever above 103°F (39.4°C)\n"
            "• Fever lasting more than 3 days\n"
            "• Fever with severe headache, rash, or difficulty breathing\n"
            "• Fever with stiff neck or confusion\n"
            "• Infant under 3 months with ANY fever\n"
            "• Fever with persistent vomiting\n\n"
            "**I can help you find urgent care or a hospital if needed.**\n\n"
            "What's your current temperature?",
        metadata: {'intent': 'symptom_check', 'symptom': 'fever', 'recommend_hospital': false},
      );
    }

    // ==================== ABDOMINAL PAIN ====================
    if (lowerText.contains('stomach pain') ||
        lowerText.contains('stomach hurts') ||
        lowerText.contains('abdominal pain') ||
        lowerText.contains('belly pain')) {
      return AIMessage.ai(
        "I understand you have abdominal pain. Let me help assess this:\n\n"
            "**Common Causes:**\n"
            "• Indigestion or gas\n"
            "• Gastroenteritis (stomach flu)\n"
            "• Food poisoning\n"
            "• Constipation\n"
            "• Menstrual cramps\n\n"
            "**Home Care:**\n"
            "1. Rest and avoid solid foods for a few hours\n"
            "2. Sip clear fluids (water, clear broth)\n"
            "3. Apply heating pad to abdomen\n"
            "4. Avoid irritating foods (spicy, fatty, acidic)\n\n"
            "** SEEK IMMEDIATE CARE if you have:**\n"
            "• Severe pain that's getting worse\n"
            "• Pain in lower right abdomen (possible appendicitis)\n"
            "• Fever with abdominal pain\n"
            "• Vomiting blood or blood in stool\n"
            "• Rigid, board-like abdomen\n"
            "• Pregnant with severe pain\n"
            "• Can't pass gas or have bowel movement\n\n"
            "**I can help you find the nearest emergency room or urgent care.**\n\n"
            "Where is the pain located? How severe is it (1-10)?",
        metadata: {'intent': 'symptom_check', 'symptom': 'abdominal_pain', 'recommend_hospital': false},
      );
    }

    // ==================== COLD/FLU ====================
    if (lowerText.contains('cold') ||
        lowerText.contains('flu') ||
        lowerText.contains('cough') ||
        lowerText.contains('runny nose') ||
        lowerText.contains('sore throat') ||
        lowerText.contains('congestion')) {
      return AIMessage.ai(
        "It sounds like you might have cold or flu symptoms. Here's what you can do:\n\n"
            "**Cold vs Flu:**\n"
            "• **Cold:** Gradual onset, runny nose, sneezing, mild symptoms\n"
            "• **Flu:** Sudden onset, high fever, body aches, severe fatigue\n\n"
            "**Home Treatment:**\n"
            "1. **Rest:** Get plenty of sleep (7-9 hours)\n"
            "2. **Fluids:** Drink lots of water, warm tea, broth\n"
            "3. **Humidity:** Use humidifier or breathe steam\n"
            "4. **Gargle:** Salt water for sore throat\n"
            "5. **OTC meds:** Decongestants, pain relievers (if appropriate)\n"
            "6. **Vitamin C:** May help reduce duration\n"
            "7. **Honey:** For cough (don't give to infants under 1)\n\n"
            "**See a doctor if:**\n"
            "• Symptoms last more than 10 days\n"
            "• Difficulty breathing\n"
            "• High fever (103°F+) or fever lasting 3+ days\n"
            "• Severe headache or sinus pain\n"
            "• Wheezing\n"
            "• Chest pain or pressure\n\n"
            "**Need medical attention? I can help you find urgent care nearby.**\n\n"
            "Are you experiencing fever along with these symptoms?",
        metadata: {'intent': 'symptom_check', 'symptom': 'cold_flu', 'recommend_hospital': false},
      );
    }

    // ==================== INJURY/SPRAIN ====================
    if (lowerText.contains('sprain') ||
        lowerText.contains('twisted') ||
        lowerText.contains('ankle') ||
        lowerText.contains('wrist') ||
        lowerText.contains('injury') && (lowerText.contains('ankle') || lowerText.contains('knee'))) {
      return AIMessage.ai(
        "For a sprain or minor injury, follow the **R.I.C.E.** method:\n\n"
            "**R - Rest**\n"
            "• Avoid putting weight on the injured area\n"
            "• Use crutches if needed\n\n"
            "**I - Ice**\n"
            "• Apply ice for 15-20 minutes every 2-3 hours\n"
            "• Use ice pack or frozen vegetables wrapped in towel\n"
            "• Never apply ice directly to skin\n\n"
            "**C - Compression**\n"
            "• Wrap with elastic bandage\n"
            "• Not too tight - should be snug but not cutting off circulation\n\n"
            "**E - Elevation**\n"
            "• Raise injured area above heart level\n"
            "• Use pillows when sitting or lying down\n\n"
            "**Pain Relief:**\n"
            "• Ibuprofen or acetaminophen (follow package directions)\n\n"
            "** Seek medical care if:**\n"
            "• Unable to put any weight on it\n"
            "• Severe pain or swelling\n"
            "• Numbness or tingling\n"
            "• Joint looks deformed\n"
            "• Heard a 'pop' at time of injury\n"
            "• No improvement after 48 hours\n\n"
            "**Need X-rays or evaluation? I can help you find urgent care or orthopedic clinics.**\n\n"
            "Can you put any weight on it?",
        metadata: {'intent': 'first_aid', 'symptom': 'sprain', 'recommend_hospital': false},
      );
    }

    // ==================== BURNS ====================
    if (lowerText.contains('burn') || lowerText.contains('burned')) {
      return AIMessage.ai(
        "For **minor burns** (first-degree, small second-degree):\n\n"
            "**Immediate Care:**\n"
            "1. **Cool the burn:** Hold under cool (not cold) running water for 10-15 minutes\n"
            "2. **Remove jewelry:** Take off rings, watches before swelling\n"
            "3. **Don't use ice:** Can cause more damage\n"
            "4. **Don't pop blisters:** This can cause infection\n\n"
            "**After Cooling:**\n"
            "1. Apply aloe vera gel or burn ointment\n"
            "2. Cover with sterile, non-stick bandage\n"
            "3. Take pain reliever if needed\n"
            "4. Keep clean and dry\n\n"
            "**What NOT to do:**\n"
            "• Don't apply butter, oil, or ice\n"
            "• Don't use cotton balls (fibers stick)\n"
            "• Don't break blisters\n\n"
            "** SEEK IMMEDIATE MEDICAL CARE for:**\n"
            "• Burns larger than 3 inches\n"
            "• Burns on face, hands, feet, genitals, or major joints\n"
            "• Third-degree burns (white, charred, or leathery)\n"
            "• Chemical or electrical burns\n"
            "• Burns in elderly, infants, or those with medical conditions\n"
            "• Signs of infection (increased pain, redness, swelling, pus)\n\n"
            "**I can help you find the nearest urgent care or ER for burn treatment.**\n\n"
            "How large is the burn? Where is it located?",
        metadata: {'intent': 'first_aid', 'symptom': 'burn', 'recommend_hospital': false},
      );
    }

    // ==================== MENTAL HEALTH ====================
    if (lowerText.contains('anxious') ||
        lowerText.contains('anxiety') ||
        lowerText.contains('depressed') ||
        lowerText.contains('depression') ||
        lowerText.contains('stress') ||
        lowerText.contains('panic attack') ||
        lowerText.contains('worried')) {
      return AIMessage.ai(
        "I hear that you're dealing with difficult emotions. Mental health is just as important as physical health.\n\n"
            "**Immediate Coping Strategies:**\n"
            "1. **Breathing:** Deep breaths - inhale 4 counts, hold 4, exhale 4\n"
            "2. **Grounding:** Name 5 things you see, 4 you hear, 3 you can touch\n"
            "3. **Movement:** Take a short walk or do gentle stretches\n"
            "4. **Connect:** Reach out to someone you trust\n"
            "5. **Self-compassion:** Be kind to yourself\n\n"
            "**Professional Help:**\n"
            "• Talk to your doctor about therapy or medication\n"
            "• Consider counseling or therapy (many offer online sessions)\n"
            "• Join support groups\n"
            "• Consider medication evaluation if symptoms persist\n\n"
            "**Crisis Resources Available 24/7:**\n"
            " **988** - Suicide & Crisis Lifeline (call or text)\n"
            " **1-800-662-4357** - SAMHSA Mental Health Helpline\n"
            " **Text 'HELLO' to 741741** - Crisis Text Line\n"
            " **1-800-273-8255** - National Suicide Prevention Lifeline\n\n"
            " **If you're in immediate danger or having thoughts of self-harm, please call 988 or 911 right now.**\n\n"
            "**I can help you find mental health services, therapists, or crisis centers nearby.**\n\n"
            "Would you like to talk more about what you're experiencing?",
        metadata: {'intent': 'mental_health', 'recommend_hospital': false},
      );
    }

    // ==================== MEDICATION INFO ====================
    if (lowerText.contains('medication') ||
        lowerText.contains('medicine') ||
        lowerText.contains('drug') ||
        lowerText.contains('prescription') ||
        lowerText.contains('pill')) {
      return AIMessage.ai(
        "I can provide general medication information. What would you like to know?\n\n"
            "**I can help with:**\n"
            "• Common medications and their uses\n"
            "• General dosage guidelines\n"
            "• Potential side effects\n"
            "• Drug interactions (general info)\n"
            "• Over-the-counter vs prescription\n\n"
            " **Important:** Always consult your doctor or pharmacist for:\n"
            "• Prescription medications specific to you\n"
            "• Exact dosing for your situation\n"
            "• Interactions with YOUR medications\n"
            "• Allergies or contraindications\n"
            "• Changing or stopping medications\n\n"
            "**Need to fill a prescription? I can help you find nearby pharmacies.**\n\n"
            "What medication are you asking about?",
        metadata: {'intent': 'medication_info', 'recommend_hospital': false},
      );
    }

    // ==================== FIND HOSPITAL/DOCTOR ====================
    if (lowerText.contains('find hospital') ||
        lowerText.contains('find doctor') ||
        lowerText.contains('nearest hospital') ||
        lowerText.contains('where is the hospital') ||
        lowerText.contains('urgent care') ||
        lowerText.contains('emergency room') ||
        lowerText.contains('pharmacy')) {
      return AIMessage.ai(
        "I can help you find nearby medical facilities! \n\n"
            "**What I can find:**\n"
            "• Hospitals with emergency rooms\n"
            "• Urgent care centers\n"
            "• Walk-in clinics\n"
            "• Pharmacies\n"
            "• Specialized medical facilities\n\n"
            "**What you'll get:**\n"
            "✓ Distance from your location\n"
            "✓ Ratings and reviews\n"
            "✓ Estimated wait times\n"
            "✓ Operating hours\n"
            "✓ One-tap calling\n"
            "✓ Google Maps directions\n\n"
            "**Click the 'Find Nearby Hospitals' button below to search for medical facilities near you!**\n\n"
            "What type of facility are you looking for?",
        metadata: {'intent': 'find_hospital', 'recommend_hospital': true},
      );
    }

    // ==================== EMERGENCY KEYWORDS ====================
    if (lowerText.contains('emergency') ||
        lowerText.contains('911') ||
        lowerText.contains('urgent') ||
        lowerText.contains('help me') ||
        lowerText.contains('dying')) {
      return AIMessage.ai(
        " **FOR LIFE-THREATENING EMERGENCIES:**\n\n"
            "**CALL 911 IMMEDIATELY for:**\n"
            "• Chest pain or heart attack symptoms\n"
            "• Difficulty breathing or choking\n"
            "• Severe bleeding that won't stop\n"
            "• Loss of consciousness\n"
            "• Stroke symptoms (F.A.S.T. - Face drooping, Arm weakness, Speech difficulty, Time to call 911)\n"
            "• Severe allergic reaction (anaphylaxis)\n"
            "• Poisoning or overdose\n"
            "• Severe burns\n"
            "• Seizures\n"
            "• Head injury with confusion\n\n"
            " **Quick Actions in This App:**\n"
            "• Use the **Panic Button** on home screen (big red button)\n"
            "• Use **Fire Emergency** button for fires\n"
            "• Your emergency contacts will be notified with your location\n"
            "• **I can help you find the nearest emergency room right now**\n\n"
            "**Important Numbers:**\n"
            " **911** - Emergency Services\n"
            " **1-800-222-1222** - Poison Control\n"
            " **988** - Suicide & Crisis Lifeline\n\n"
            "Are you experiencing a medical emergency right now?",
        metadata: {'intent': 'emergency', 'recommend_hospital': true},
      );
    }

    // ==================== FIRST AID ====================
    if (lowerText.contains('first aid') ||
        lowerText.contains('how to treat') ||
        lowerText.contains('what should i do')) {
      return AIMessage.ai(
        "I can help with first aid guidance! What type of injury or situation are you dealing with?\n\n"
            "**Common First Aid Topics:**\n"
            "• **Cuts & Scrapes** - Cleaning and bandaging\n"
            "• **Burns** - Cooling and care (minor burns only)\n"
            "• **Sprains & Strains** - R.I.C.E. method\n"
            "• **Bleeding** - Applying pressure correctly\n"
            "• **Choking** - Heimlich maneuver\n"
            "• **CPR** - Emergency cardiac care\n"
            "• **Bee Stings** - Removal and treatment\n"
            "• **Nosebleeds** - Proper technique\n"
            "• **Fractures** - Immobilization\n\n"
            " **Call 911 for severe injuries**\n\n"
            "Please describe the injury so I can provide specific guidance.\n\n"
            "If you need professional care, **I can help you find urgent care or hospitals nearby.**",
        metadata: {'intent': 'first_aid', 'recommend_hospital': false},
      );
    }

    // ==================== PREGNANCY ====================
    if (lowerText.contains('pregnant') ||
        lowerText.contains('pregnancy') ||
        lowerText.contains('expecting')) {
      return AIMessage.ai(
        "I can provide general pregnancy information, but it's very important that you're under the care of a healthcare provider.\n\n"
            "**Important:**\n"
            "• Regular prenatal care is essential\n"
            "• See your OB/GYN regularly\n"
            "• Take prenatal vitamins\n"
            "• Avoid alcohol, smoking, and certain medications\n\n"
            "** Seek immediate care if you experience:**\n"
            "• Severe abdominal pain\n"
            "• Heavy bleeding\n"
            "• Severe headache with vision changes\n"
            "• High fever\n"
            "• Decreased fetal movement (after 28 weeks)\n"
            "• Fluid leaking\n"
            "• Severe swelling, especially face and hands\n\n"
            "**I can help you find:**\n"
            "• OB/GYN offices\n"
            "• Hospitals with maternity wards\n"
            "• Women's health clinics\n\n"
            "What pregnancy-related question can I help with?",
        metadata: {'intent': 'pregnancy', 'recommend_hospital': false},
      );
    }

    // ==================== ALLERGIC REACTION ====================
    if (lowerText.contains('allergic') ||
        lowerText.contains('allergy') ||
        lowerText.contains('rash') ||
        lowerText.contains('hives') ||
        lowerText.contains('swelling') && lowerText.contains('face')) {
      return AIMessage.ai(
        "Let me help you assess this allergic reaction:\n\n"
            "** CALL 911 IMMEDIATELY if you have:**\n"
            "• Difficulty breathing or throat tightness\n"
            "• Swelling of face, lips, tongue, or throat\n"
            "• Rapid pulse or dizziness\n"
            "• Severe widespread rash\n"
            "• Nausea, vomiting, or diarrhea\n"
            "• Feeling of impending doom\n"
            "**This is ANAPHYLAXIS - a life-threatening emergency!**\n\n"
            "**For mild allergic reactions:**\n"
            "• Take antihistamine (Benadryl, Zyrtec, etc.)\n"
            "• Apply cool compress to rash\n"
            "• Avoid known allergen\n"
            "• Monitor symptoms closely\n\n"
            "**Watch for worsening:**\n"
            "If symptoms get worse or spread, seek immediate care.\n\n"
            "**I can help you find the nearest emergency room if symptoms worsen.**\n\n"
            "Are you having any trouble breathing or swallowing?",
        metadata: {'intent': 'emergency', 'symptom': 'allergic_reaction', 'recommend_hospital': true},
      );
    }

    // ==================== THANK YOU ====================
    if (lowerText.contains('thank') || lowerText.contains('thanks')) {
      return AIMessage.ai(
        "You're very welcome! I'm glad I could help. \n\n"
            "Remember:\n"
            "• I'm here 24/7 for health questions\n"
            "• For emergencies, always call 911\n"
            "• Use the panic button for urgent situations\n"
            "• I can help you find hospitals anytime\n\n"
            "Stay safe and healthy! Feel free to ask me anything else.",
        metadata: {'intent': 'gratitude', 'recommend_hospital': false},
      );
    }

    // ==================== DEFAULT RESPONSE ====================
    return AIMessage.ai(
      "I understand you're asking about: \"$text\"\n\n"
          "I'm here to help with:\n"
          "• **Symptom checking** - Describe what you're experiencing\n"
          "• **First aid** - Emergency care guidance\n"
          "• **Medications** - General drug information\n"
          "• **Finding hospitals** - Locate nearby medical facilities\n"
          "• **Health advice** - General wellness tips\n\n"
          "Please tell me more about your symptoms or what you need help with, and I'll do my best to assist you.\n\n"
          " **Remember:** I'm an AI assistant and cannot replace professional medical advice. For emergencies, call 911 or use the emergency buttons in this app.\n\n"
          "**Need to find a hospital or doctor? I can help with that too!**",
      metadata: {'intent': 'clarification', 'recommend_hospital': false},
    );
  }

  // Simple mock response (fallback)
  AIMessage _getMockResponse(String text) {
    return AIMessage.ai(
      "I received your message: \"$text\"\n\n"
          "I'm Doctor Annie, your AI health assistant. I can help with:\n"
          "• Symptom checking\n"
          "• First aid guidance\n"
          "• Finding nearby hospitals\n"
          "• General health information\n\n"
          "How can I assist you today?",
      metadata: {'intent': 'test_mode', 'recommend_hospital': false},
    );
  }

  void clearSession() {
    _sessionId = null;
  }
}