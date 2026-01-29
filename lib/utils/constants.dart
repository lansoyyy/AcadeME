import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // App Information
  static const String appName = 'AR Fusion';
  static const String appFullName = 'AR Fusion Mobile App';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Science Education Reimagined';

  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 100.0;

  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;

  // Font Sizes
  static const double fontXS = 10.0;
  static const double fontS = 12.0;
  static const double fontM = 14.0;
  static const double fontL = 16.0;
  static const double fontXL = 20.0;
  static const double fontXXL = 24.0;
  static const double fontTitle = 28.0;
  static const double fontDisplay = 32.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Languages
  static const List<String> supportedLanguages = [
    'English',
    'Filipino',
    'Cebuano',
  ];

  // Adherence Thresholds
  static const double excellentAdherence = 90.0;
  static const double goodAdherence = 75.0;
  static const double fairAdherence = 60.0;

  // Reward Points
  static const int pointsPerDose = 10;
  static const int pointsPerStreak = 50;
  static const int pointsPerWeekPerfect = 100;

  // Reminder Settings
  static const int defaultReminderMinutes = 15;
  static const int maxReminders = 5;

  // Image Paths
  static const String imagePath = 'assets/images/';
  static const String iconPath = 'assets/icons/';
  static const String animationPath = 'assets/animations/';

  // API Endpoints (placeholder)
  static const String baseUrl = 'https://api.mamaapp.com';

  // Google Places API
  static const String googlePlacesApiKey =
      'AIzaSyBwByaaKz7j4OGnwPDxeMdmQ4Pa50GA42o';
  static const String googlePlacesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  // Davao City coordinates
  static const double davaoCityLatitude = 7.0731;
  static const double davaoCityLongitude = 125.6128;

  // Local Storage Keys
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserType = 'user_type';
  static const String keyLanguage = 'language';
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotifications = 'notifications_enabled';
  static const String keyOfflineMode = 'offline_mode';

  // User Types
  static const String userTypeStudent = 'student';
  static const String userTypeTeacher = 'teacher';
  static const String userTypeAdmin = 'admin';

  // Grade Levels
  static const List<String> gradeLevels = ['Grade 9'];

  // Subjects
  static const List<String> subjects = [
    'Biology',
    'Chemistry',
    'Physics',
    'Earth Science',
  ];

  static const List<Map<String, String>> shsCurriculumSubjects = [
    {
      'code': 'COR 011',
      'title': '21st Century Literature from the Philippines and the World',
      'type': 'Core',
    },
    {'code': 'ABM 007', 'title': 'Applied Economics', 'type': 'Specialized'},
    {
      'code': 'HOM 001',
      'title': 'Attractions and Theme Parks (NC II)',
      'type': 'Specialized',
    },
    {'code': 'STM 002', 'title': 'Basic Calculus', 'type': 'Specialized'},
    {
      'code': 'HOM 002',
      'title': 'Bread and Pastry Production (NC II)',
      'type': 'Specialized',
    },
    {
      'code': 'ABM 009',
      'title': 'Business Enterprise Simulation',
      'type': 'Specialized',
    },
    {
      'code': 'ABM 008',
      'title': 'Business Ethics and Social Responsibility',
      'type': 'Specialized',
    },
    {'code': 'ABM 004', 'title': 'Business Finance', 'type': 'Specialized'},
    {'code': 'ABM 005', 'title': 'Business Mathematics', 'type': 'Specialized'},
    {
      'code': 'SOC 004',
      'title': 'Community Engagement, Solidarity, and Citizenship',
      'type': 'Specialized',
    },
    {
      'code': 'ICT 001',
      'title': 'Computer Programming (NC IV)',
      'type': 'Specialized',
    },
    {
      'code': 'ICT 010',
      'title': 'Computer Programming (Part 1)',
      'type': 'Specialized',
    },
    {
      'code': 'ICT 009',
      'title': 'Computer Programming (Part 2)',
      'type': 'Specialized',
    },
    {
      'code': 'COR 012',
      'title': 'Contemporary Philippine Arts from the Regions',
      'type': 'Core',
    },
    {'code': 'HUM 002', 'title': 'Creative Nonfiction', 'type': 'Specialized'},
    {'code': 'HUM 001', 'title': 'Creative Writing', 'type': 'Specialized'},
    {'code': 'SPX 001', 'title': 'Criminology Elective', 'type': 'Specialized'},
    {
      'code': 'SPX 003',
      'title': 'Culminating Activity in Criminology',
      'type': 'Specialized',
    },
    {
      'code': 'SPX 004',
      'title': 'Culminating Activity in Education',
      'type': 'Specialized',
    },
    {
      'code': 'SPX 005',
      'title': 'Culminating Activity in General Academics',
      'type': 'Specialized',
    },
    {
      'code': 'SPX 008',
      'title': 'Culminating Activity in Health',
      'type': 'Specialized',
    },
    {
      'code': 'SPX 009',
      'title': 'Culminating Activity in Hospitality and Tourism (Academic)',
      'type': 'Specialized',
    },
    {
      'code': 'HOM 008',
      'title': 'Culminating Activity in Hospitality and Tourism (TVL)',
      'type': 'Specialized',
    },
    {
      'code': 'SPX 006',
      'title': 'Culminating Activity in Humanities and Social Sciences',
      'type': 'Specialized',
    },
    {
      'code': 'ICT 002',
      'title':
          'Culminating Activity in Information and Communications Technology',
      'type': 'Specialized',
    },
    {
      'code': 'SPX 007',
      'title': 'Culminating Activity in Information Technology',
      'type': 'Specialized',
    },
    {
      'code': 'COR 010',
      'title': 'Disaster Readiness and Risk Reduction',
      'type': 'Core',
    },
    {
      'code': 'SOC 002',
      'title': 'Disciplines and Ideas in the Applied Social Sciences',
      'type': 'Specialized',
    },
    {
      'code': 'SOC 001',
      'title': 'Disciplines and Ideas in the Social Sciences',
      'type': 'Specialized',
    },
    {'code': 'COR 007', 'title': 'Earth and Life Science', 'type': 'Core'},
    {'code': 'COR 008', 'title': 'Earth Science', 'type': 'Core'},
    {'code': 'APP 001', 'title': 'Empowerment Technologies', 'type': 'Applied'},
    {
      'code': 'APP 002',
      'title': 'English for Academic and Professional Purposes',
      'type': 'Applied',
    },
    {'code': 'APP 004', 'title': 'Entrepreneurship', 'type': 'Applied'},
    {
      'code': 'APP 003',
      'title': 'Filipino sa Piling Larangan',
      'type': 'Applied',
    },
    {
      'code': 'HOM 003',
      'title': 'Food and Beverage Services (NC II)',
      'type': 'Specialized',
    },
    {
      'code': 'ABM 002',
      'title': 'Fundamentals of Accountancy, Business and Management 1',
      'type': 'Specialized',
    },
    {
      'code': 'ABM 003',
      'title': 'Fundamentals of Accountancy, Business and Management 2',
      'type': 'Specialized',
    },
    {'code': 'STM 007', 'title': 'General Biology 1', 'type': 'Specialized'},
    {'code': 'STM 008', 'title': 'General Biology 2', 'type': 'Specialized'},
    {'code': 'STM 005', 'title': 'General Chemistry 1', 'type': 'Specialized'},
    {'code': 'STM 006', 'title': 'General Chemistry 2', 'type': 'Specialized'},
    {'code': 'COR 005', 'title': 'General Mathematics', 'type': 'Core'},
    {'code': 'STM 003', 'title': 'General Physics 1', 'type': 'Specialized'},
    {'code': 'STM 004', 'title': 'General Physics 2', 'type': 'Specialized'},
    {'code': 'HOM 004', 'title': 'Housekeeping (NC II)', 'type': 'Specialized'},
    {
      'code': 'APP 007',
      'title': 'Inquiries, Investigations, and Immersion',
      'type': 'Applied',
    },
    {
      'code': 'COR 015',
      'title': 'Introduction to the Philosophy of the Human Person',
      'type': 'Core',
    },
    {
      'code': 'HUM 003',
      'title': 'Introduction to World Religions and Belief Systems',
      'type': 'Specialized',
    },
    {'code': 'SPX 002', 'title': 'IT Elective', 'type': 'Specialized'},
    {
      'code': 'COR 003',
      'title': 'Komunikasyon at Pananaliksik sa Wika at Kulturang Filipino',
      'type': 'Core',
    },
    {
      'code': 'HOM 005',
      'title': 'Local Guiding Services (NC II)',
      'type': 'Specialized',
    },
    {
      'code': 'COR 016',
      'title': 'Media and Information Literacy',
      'type': 'Core',
    },
    {
      'code': 'COR 001',
      'title': 'Oral Communication in Context',
      'type': 'Core',
    },
    {
      'code': 'ABM 001',
      'title': 'Organization and Management',
      'type': 'Specialized',
    },
    {
      'code': 'COR 004',
      'title':
          "Pagbasa at Pagsusuri ng Iba't Ibang Teksto Tungo sa Pananaliksik",
      'type': 'Core',
    },
    {'code': 'COR 014', 'title': 'Personal Development', 'type': 'Core'},
    {
      'code': 'SOC 003',
      'title': 'Philippine Politics and Governance',
      'type': 'Specialized',
    },
    {
      'code': 'COR 017',
      'title': 'Physical Education and Health 1',
      'type': 'Core',
    },
    {
      'code': 'COR 018',
      'title': 'Physical Education and Health 2',
      'type': 'Core',
    },
    {
      'code': 'COR 019',
      'title': 'Physical Education and Health 3',
      'type': 'Core',
    },
    {
      'code': 'COR 020',
      'title': 'Physical Education and Health 4',
      'type': 'Core',
    },
    {'code': 'COR 009', 'title': 'Physical Science', 'type': 'Core'},
    {'code': 'APP 005', 'title': 'Practical Research 1', 'type': 'Applied'},
    {'code': 'APP 006', 'title': 'Practical Research 2', 'type': 'Applied'},
    {'code': 'STM 001', 'title': 'Pre-Calculus', 'type': 'Specialized'},
    {
      'code': 'ABM 006',
      'title': 'Principles of Marketing',
      'type': 'Specialized',
    },
    {'code': 'COR 002', 'title': 'Reading and Writing Skills', 'type': 'Core'},
    {
      'code': 'STM 009',
      'title': 'Research in Science, Technology, Engineering, and Mathematics',
      'type': 'Specialized',
    },
    {'code': 'SPO 001', 'title': 'Safety and First Aid', 'type': 'Specialized'},
    {
      'code': 'SSP 001',
      'title': 'SHS Student Success Program 1',
      'type': 'Program',
    },
    {
      'code': 'SSP 002',
      'title': 'SHS Student Success Program 2',
      'type': 'Program',
    },
    {
      'code': 'SSP 003',
      'title': 'SHS Student Success Program 3',
      'type': 'Program',
    },
    {
      'code': 'SSP 004',
      'title': 'SHS Student Success Program 4',
      'type': 'Program',
    },
    {'code': 'COR 006', 'title': 'Statistics and Probability', 'type': 'Core'},
    {
      'code': 'HOM 006',
      'title': 'Tourism Promotion Services (NC II)',
      'type': 'Specialized',
    },
    {
      'code': 'HOM 007',
      'title': 'Travel Services (NC II)',
      'type': 'Specialized',
    },
    {
      'code': 'HUM 004',
      'title': 'Trends, Networks, and Critical Thinking in the 21st Century',
      'type': 'Specialized',
    },
    {
      'code': 'COR 013',
      'title': 'Understanding Culture, Society, and Politics',
      'type': 'Core',
    },
  ];

  // Grade 9 Lessons with AR Items
  static const List<Map<String, dynamic>> grade9Lessons = [
    {
      'id': 'g9_volcanoes',
      'title': 'Volcanoes',
      'subject': 'Earth Science',
      'grade': 'Grade 9',
      'quarter': 'Quarter 3',
      'description':
          'Investigate types of volcanoes, eruption styles, and their effects on people and the environment.',
      'arItems': ['3D Volcano Model', 'Eruption Simulation', 'Lava Flow Paths'],
      'icon': Icons.terrain_outlined,
      'color': 'earthScience',
    },
    {
      'id': 'g9_earthquakes',
      'title': 'Earthquakes',
      'subject': 'Earth Science',
      'grade': 'Grade 9',
      'quarter': 'Quarter 3',
      'description':
          'Understand how earthquakes happen, seismic waves, and how they are measured.',
      'arItems': [
        'Fault Line Models',
        'Seismic Wave Animation',
        'Earthquake Intensity Map',
      ],
      'icon': Icons.speed_outlined,
      'color': 'earthScience',
    },
    {
      'id': 'g9_climate',
      'title': 'Climate and Weather',
      'subject': 'Earth Science',
      'grade': 'Grade 9',
      'quarter': 'Quarter 3',
      'description':
          'Explore factors that affect climate, weather patterns, and climate change impacts.',
      'arItems': [
        'Climate Graphs',
        'Atmospheric Layers',
        'Weather System Simulation',
      ],
      'icon': Icons.cloud,
      'color': 'earthScience',
    },
    {
      'id': 'g9_constellations',
      'title': 'Constellations',
      'subject': 'Earth Science',
      'grade': 'Grade 9',
      'quarter': 'Quarter 3',
      'description':
          'Identify major constellations and learn how they are used for navigation and seasons.',
      'arItems': [
        'Night Sky Map',
        'Constellation Lines',
        'Star Information Cards',
      ],
      'icon': Icons.star,
      'color': 'earthScience',
    },
    {
      'id': 'g9_energy',
      'title': 'Energy and Work',
      'subject': 'Physics',
      'grade': 'Grade 9',
      'quarter': 'Quarter 3',
      'description':
          'Learn about different forms of energy, work, and the law of conservation of energy.',
      'arItems': [
        'Energy Transformations',
        'Work Done Simulations',
        'Energy Bar Charts',
      ],
      'icon': Icons.bolt,
      'color': 'physics',
    },
    {
      'id': 'g9_forces',
      'title': 'Forces',
      'subject': 'Physics',
      'grade': 'Grade 9',
      'quarter': 'Quarter 4',
      'description':
          'Understand different types of forces and how they affect the motion of objects.',
      'arItems': [
        'Force Diagrams',
        'Push and Pull Interactions',
        'Balanced vs Unbalanced Forces',
      ],
      'icon': Icons.arrow_upward,
      'color': 'physics',
    },
    {
      'id': 'g9_motion',
      'title': 'Motion',
      'subject': 'Physics',
      'grade': 'Grade 9',
      'quarter': 'Quarter 4',
      'description':
          'Describe motion using distance-time graphs, speed, velocity, and acceleration.',
      'arItems': [
        'Motion Graphs',
        'Moving Object Models',
        'Speed and Acceleration Sliders',
      ],
      'icon': Icons.directions_run,
      'color': 'physics',
    },
    {
      'id': 'g9_electricity',
      'title': 'Electricity',
      'subject': 'Physics',
      'grade': 'Grade 9',
      'quarter': 'Quarter 4',
      'description':
          'Explore electric circuits, current, voltage, and resistance using interactive models.',
      'arItems': [
        'Circuit Builder',
        'Current Flow Animation',
        'Series vs Parallel Circuits',
      ],
      'icon': Icons.bolt,
      'color': 'physics',
    },
    {
      'id': 'g9_waves',
      'title': 'Waves',
      'subject': 'Physics',
      'grade': 'Grade 9',
      'quarter': 'Quarter 4',
      'description':
          'Visualize mechanical and electromagnetic waves and how wavelength and frequency relate.',
      'arItems': [
        'Wave Interference',
        'Sound Wave Visualizer',
        'Light Spectrum',
      ],
      'icon': Icons.graphic_eq,
      'color': 'physics',
    },
  ];

  // Grade 10 Lessons with AR Items
  static const List<Map<String, dynamic>> grade10Lessons = [];

  // All Lessons Combined
  static const List<Map<String, dynamic>> allLessons = [
    ...grade9Lessons,
    ...grade10Lessons,
  ];

  // Medication Status
  static const String statusTaken = 'taken';
  static const String statusMissed = 'missed';
  static const String statusPending = 'pending';
  static const String statusSkipped = 'skipped';

  // Severity Levels
  static const String severityMild = 'mild';
  static const String severityModerate = 'moderate';
  static const String severitySerious = 'serious';
  static const String severityUrgent = 'urgent';
}

/// Text Styles
class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: AppConstants.fontDisplay,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: AppConstants.fontTitle,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: AppConstants.fontXXL,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: AppConstants.fontXL,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: AppConstants.fontL,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: AppConstants.fontM,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppConstants.fontL,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppConstants.fontM,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: AppConstants.fontS,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: AppConstants.fontM,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: AppConstants.fontS,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: AppConstants.fontXS,
    fontWeight: FontWeight.w500,
  );
}
