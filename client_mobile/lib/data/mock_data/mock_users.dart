// Mock user data for login by role
List<Map<String, String>> mockUsers = [
  // Farmer (Agriculteur)
  {
    'email': 'farmer@gmail.com',
    'password': 'farmer123',
    'role': 'Agriculteur',
    'fullName': 'Ali Farmer',
    'phone': '0600000001',
    'city': 'Agadir',
    'farmingType': 'Agriculture',
    'mainProducts': 'Maize, Wheat',
  },
  // Usine (Factory)
  {
    'email': 'factory@gmail.com',
    'password': 'factory123',
    'role': 'Usine',
    'fullName': 'Sara Usine',
    'phone': '0600000002',
    'city': 'Casablanca',
    'companyName': 'AgriFactory',
    'productTypes': 'Canned Vegetables, Flour',
  },
  // Transporteur (Transporter)
  {
    'email': 'transporter@gmail.com',
    'password': 'trans123',
    'role': 'Transporteur',
    'fullName': 'Mohamed Transport',
    'phone': '0600000003',
    'city': 'Marrakech',
    'vehicleType': 'Truck',
    'capacity': '10 Tons',
  },
  // Financeur (Financer)
  {
    'email': 'financer@gmail.com',
    'password': 'financer123',
    'role': 'Financeur',
    'fullName': 'Imane Finance',
    'phone': '0600000004',
    'city': 'Rabat',
    'fundingType': 'Microloan',
    'budgetRange': '10000-50000 MAD',
  },
];
