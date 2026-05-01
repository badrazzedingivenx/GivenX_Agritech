# 🌾 AgriFlow - Agricultural Management Mobile App

## 📌 Overview

AgriFlow is a mobile application developed using **Flutter** with a local backend powered by **JSON Server (Node.js)**.
The app aims to digitalize agricultural workflows by connecting farmers and cooperatives, allowing them to manage requests and offers efficiently.

---

## 🧰 Technologies Used

* **Flutter** (Dart)
* **Node.js**
* **JSON Server**
* REST API
* Git & GitHub

---

## 📁 Project Structure

```
client_mobile/
│
├── lib/                # Flutter application source code
├── json_server/        # Backend (db.json + server.js)
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

---

## ⚙️ Installation & Setup

### 1️⃣ Clone the repository

```bash
git clone < https://github.com/badrazzedingivenx/GivenX_Agritech.git >
cd client_mobile
```

---

### 2️⃣ Install Flutter dependencies

```bash
flutter pub get
```

---

### 3️⃣ Start JSON Server (Backend)

```bash
cd json_server
npm install
npm start
```

Server will run on:

```
http://localhost:3000
```

---

### 4️⃣ Run the Flutter App

```bash
flutter run
```

---

## 📱 API Configuration

* **Android Emulator:**

```
http://10.0.2.2:3000
```

## 📦 Build APK

To generate APK:

```bash
flutter build apk
```

Output location:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## ⚠️ Important Notes

* This project uses **JSON Server**, which is a mock backend (not suitable for production)
* Make sure the backend server is running before launching the app
* Ensure correct API base URL configuration

---
## 👤 Author

* **Soukaina Jouah**

