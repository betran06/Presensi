# Employee Attendance App (Flutter + Laravel API)

A simple mobile attendance (presensi) application built using **Flutter & Dart**, integrated with a **Laravel backend API**.  
This project was created for a Mobile Application course and provides employee check-in/check-out functionality using GPS location. The app communicates with a Laravel-based REST API for authentication and attendance submission while storing user session/token locally using `shared_preferences`.

---

## 🌟 Features
- Login via Laravel backend API
- Check-in & check-out using device GPS (Location package)
- Send attendance data to Laravel API using HTTP requests
- Store authentication token/session locally using `shared_preferences`
- Map visualization using **Syncfusion Maps**
- Simple UI for home, login, and presence submission

---

## 🧩 Tech Stack

### **Frontend (Mobile) – Flutter**
- Flutter SDK (Dart SDK ^3.7.0)
- `location` → get real-time GPS coordinates  
- `http` → API communication with Laravel backend  
- `shared_preferences` → store user token/session locally  
- `syncfusion_flutter_maps` → map UI  
- `cupertino_icons`  

### **Backend – Laravel API**
(Backend not included here, but the mobile app is built for it)
- Laravel API endpoints for:
  - Login
  - Save attendance
  - Retrieve user info (optional)

---

## 📁 Project Structure (simplified)


A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
