# 📊 PANDUAN PRESENTASI - Bengkel Pakistunes

**Mobile Workshop Management System**  
**UAS Pemrograman Mobile 2 - 23552011390**  
**Mahasiswa:** Rizky Surya  
**Demo:** https://bengkels.web.app

---

## 🎯 STRUKTUR PRESENTASI (25 Slides)

### **SECTION 1: INTRODUCTION (3 Slides)**

#### **Slide 1: Cover**
- Logo Bengkel Pakistunes (assets/images/logo.png)
- Judul: "Bengkel Pakistunes"
- Subtitle: "Mobile Workshop Management System"
- Nama: Rizky Surya (23552011390)
- UAS Pemrograman Mobile 2

#### **Slide 2: Problem Statement**
**Latar Belakang:**
- Bengkel tradisional masih manual dalam pencatatan
- Sulit tracking stok parts dan booking service
- Customer kesulitan cek ketersediaan dan harga

**Kebutuhan:**
- Sistem terintegrasi untuk bengkel modern
- Platform e-commerce untuk spare parts
- Booking system untuk service motor

#### **Slide 3: Solution Overview**
**Screenshots:** `04_home_screen.png` + `27_admin_dashboard.png`

**Solusi yang Ditawarkan:**
- ✅ E-commerce platform untuk spare parts
- ✅ Service booking system dengan time slot
- ✅ Real-time order tracking
- ✅ Admin dashboard untuk management
- ✅ Multi-platform (Android, iOS, Web)

---

### **SECTION 2: USER FEATURES (8 Slides)**

#### **Slide 4: Authentication System**
**Screenshots:** `02_login_screen.png` + `03_register_screen.png`

**Features:**
- Email/Password authentication (Firebase Auth)
- Role-based access (User & Admin)
- Secure session management
- Custom logo branding

#### **Slide 5: Product Catalog & Home**
**Screenshots:** `04_home_screen.png` + `05_product_list.png`

**Features:**
- Custom banner promo
- 4 Kategori produk (Peralatan Service, Oli & Pelumas, Suku Cadang, Sparepart Racing)
- Search & filter functionality
- Grid view dengan stock indicator

#### **Slide 6: Product Detail & Shopping Cart**
**Screenshots:** `06_product_detail.png` + `07_shopping_cart.png`

**Features:**
- Product detail dengan stock real-time
- Add to cart dengan quantity control
- Shopping cart management
- Price calculation otomatis

#### **Slide 7: Checkout & Payment**
**Screenshots:** `08_checkout_form.png` + `10_order_success.png`

**Features:**
- Address selection (multiple addresses support)
- Payment method (Transfer Bank)
- Order summary & total
- Order confirmation

#### **Slide 8: Order Management**
**Screenshots:** `11_order_history.png` + `12_order_detail.png`

**Features:**
- Order history dengan filter status
- Status tracking (Pending → Diproses → Dikirim → Selesai)
- Order detail lengkap
- Payment proof view
- Cancel order (jika pending)

#### **Slide 9: Service Booking System**
**Screenshots:** `14_service_list.png` + `16_booking_timeslot.png`

**Features:**
- 5 Service options (Ganti Oli, Service Rutin, Tune Up, Repair, Modifikasi)
- Calendar untuk pilih tanggal
- **Time slot 08:00-17:00** (10 slots)
- Real-time availability check
- Booking validation (jam kerja only)

#### **Slide 10: Wishlist & Reviews**
**Screenshots:** `19_wishlist.png` + `20_product_reviews.png`

**Features:**
- Add/remove favorite products
- Product rating (1-5 stars)
- User reviews & comments
- Review timestamp

#### **Slide 11: Profile & Settings**
**Screenshots:** `22_profile_screen.png` + `24_address_list.png`

**Features:**
- Profile management (nama, email, phone)
- Multiple address support
- Default address selection
- Notifications center
- Quick access menu

---

### **SECTION 3: ADMIN FEATURES (5 Slides)**

#### **Slide 12: Admin Dashboard**
**Screenshots:** `27_admin_dashboard.png` + `28_admin_menu.png`

**Features:**
- Statistics overview (Total Orders, Bookings, Revenue)
- Recent orders list
- Quick actions menu
- Admin navigation drawer

#### **Slide 13: Product Management**
**Screenshots:** `29_manage_products.png` + `30_add_product.png`

**Features:**
- CRUD operations untuk produk
- **URL-based image** (ImgBB/Imgur integration)
- Stock management
- Kategori & harga control
- Search & filter produk

**Note:** Menggunakan URL eksternal karena Firebase Storage requires Blaze Plan

#### **Slide 14: Order Management**
**Screenshots:** `33_manage_orders.png`

**Features:**
- View all orders dengan filter
- Payment verification system
- Update order status
- Customer information view
- Order items detail

#### **Slide 15: Booking Management**
**Screenshots:** `37_manage_bookings.png` + `39_update_booking_status.png`

**Features:**
- View all bookings dengan date & time
- Time slot availability management
- Update booking status
- Customer & service info
- **Jam kerja validation** (08:00-17:00)

#### **Slide 16: Service Management**
**Screenshots:** `40_manage_services.png` + `41_add_service.png`

**Features:**
- CRUD services
- Price & duration setup
- Service category
- Description management

---

### **SECTION 4: TECHNICAL IMPLEMENTATION (6 Slides)**

#### **Slide 17: Technology Stack**

```
┌─────────────────────────────────────────────┐
│           TECHNOLOGY STACK                   │
└─────────────────────────────────────────────┘

Frontend Framework:
  └─ Flutter 3.10.7 (Dart)
  └─ Material Design 3
  └─ Responsive UI (Mobile + Web)

Backend Services (Firebase):
  ├─ Authentication (Email/Password)
  ├─ Firestore Database (NoSQL, Real-time)
  └─ Hosting (https://bengkels.web.app)

External Services:
  └─ ImgBB/Imgur (Image Hosting)

Platforms Supported:
  ├─ Android (APK)
  ├─ iOS
  └─ Web (Progressive Web App)

Development Tools:
  ├─ VS Code + Flutter Extension
  ├─ Firebase Console
  └─ Git (Version Control)
```

#### **Slide 18: Firebase Authentication**
**Screenshots:** `43_firebase_authentication.png` + `44_firebase_auth_methods.png`

**Implementation:**
- Email/Password provider enabled
- Secure user registration & login
- Role-based access (isAdmin field)
- Session management
- Password reset functionality

**Security:**
```dart
// User roles stored in Firestore
users/{userId} {
  email: string,
  name: string,
  role: 'user' | 'admin',
  createdAt: timestamp
}
```

#### **Slide 19: Firestore Database Structure**
**Screenshots:** `45_firestore_collections.png` + `46_firestore_users.png`

**Collections:**
```
firestore/
├─ users/          (User profiles & roles)
├─ products/       (Product catalog)
├─ orders/         (Customer orders)
├─ bookings/       (Service bookings)
├─ services/       (Available services)
├─ reviews/        (Product reviews)
├─ favorites/      (User wishlists)
└─ addresses/      (Delivery addresses)
```

**Features:**
- Real-time synchronization
- Offline persistence
- Query optimization with indexes
- Security rules implementation

#### **Slide 20: Firestore Data Models**
**Screenshots:** `47_firestore_products.png` + `48_firestore_orders.png`

**Product Model:**
```dart
{
  id: string,
  name: string,
  price: int,
  stock: int,
  category: string,
  imageUrl: string,  // URL eksternal
  description: string,
  rating: double,
  createdAt: timestamp
}
```

**Order Model:**
```dart
{
  id: string,
  userId: string,
  items: array,
  totalAmount: int,
  status: 'pending' | 'diproses' | 'dikirim' | 'selesai',
  paymentProof: string,
  address: object,
  createdAt: timestamp
}
```

#### **Slide 21: Firebase Hosting Deployment**
**Screenshots:** `51_hosting_dashboard.png` + `52_hosting_usage.png`

**Deployment Details:**
- **URL:** https://bengkels.web.app
- **CDN:** Global distribution
- **SSL:** Automatic HTTPS
- **Performance:** Optimized with caching

**Deployment Process:**
```bash
1. flutter build web
2. firebase deploy --only hosting
3. Live in production! ✅
```

**Metrics:**
- 34 files deployed
- Fast load time
- Mobile-responsive
- PWA capabilities

#### **Slide 22: Application Architecture**

```
┌─────────────────────────────────────────────┐
│      ARCHITECTURE PATTERN: MVC              │
└─────────────────────────────────────────────┘

Project Structure:
lib/
├── models/              (Data Models)
│   ├── product.dart
│   ├── order.dart
│   ├── booking.dart
│   └── user.dart
│
├── services/            (Business Logic)
│   ├── auth_service.dart
│   ├── catalog_service.dart
│   └── booking_service.dart
│
├── screens/             (UI Layer)
│   ├── auth/           (Login, Register)
│   ├── product/        (List, Detail, Cart)
│   ├── order/          (History, Detail, Tracking)
│   ├── booking/        (Services, Calendar, Timeslot)
│   ├── profile/        (Profile, Edit, Addresses)
│   └── admin/          (Dashboard, Management)
│
└── theme/              (Design System)
    └── app_theme.dart  (Colors, Typography)

Key Design Principles:
✅ Separation of Concerns
✅ Reusable Components
✅ State Management (StatefulWidget)
✅ Responsive Design
✅ Clean Code Structure
```

---

### **SECTION 5: DEMO & CONCLUSION (3 Slides)**

#### **Slide 23: Live Demo**

**QR Code:** https://bengkels.web.app

**Test Credentials:**
```
Admin Account:
  Email: admin@test.com
  Password: admin123

User Account:
  Email: user@test.com
  Password: user123
```

**Demo Flow:**
1. Login sebagai user → Browse products → Add to cart → Checkout
2. Login sebagai admin → Add product → Manage order → Update status
3. Service booking → Pilih tanggal & time slot

**APK Download:**
- GitHub: github.com/RizkySurya1/UAS_PemMob2_23552011390
- File: app-release.apk (~50MB)

#### **Slide 24: Key Achievements**

**Features Implemented:**
- ✅ 50+ Features across user & admin
- ✅ 30+ Screens with responsive design
- ✅ Real-time data synchronization
- ✅ Multi-platform support (Android, iOS, Web)
- ✅ Role-based access control
- ✅ Production deployment

**Technical Highlights:**
- ✅ Clean architecture (MVC pattern)
- ✅ Firebase integration (Auth, Firestore, Hosting)
- ✅ Security rules implementation
- ✅ Image hosting workaround (URL-based)
- ✅ Time slot validation system
- ✅ Order tracking & status management

**Performance:**
- ⚡ Fast loading time
- 📱 Mobile-optimized UI
- 🌐 Progressive Web App
- 🔒 Secure authentication

#### **Slide 25: Thank You & Q&A**

**Contact Information:**
```
Mahasiswa: Rizky Surya
NIM: 23552011390
Mata Kuliah: Pemrograman Mobile 2

GitHub Repository:
https://github.com/RizkySurya1/UAS_PemMob2_23552011390

Live Demo:
https://bengkels.web.app

Documentation:
README.md (790+ lines)
SCREENSHOT_GUIDE.md (Full guide)
```

**Questions?**
- Technical implementation
- Firebase integration
- Architecture decisions
- Feature demonstrations

---

## 🎨 DESIGN GUIDELINES

### **Color Scheme:**
- **Primary:** Blue (#2196F3)
- **Accent:** Orange (#FF9800)
- **Background:** White/Light gray
- **Text:** Dark gray (#212121)

### **Slide Design Tips:**
1. **Consistency:** Gunakan template yang sama
2. **Readability:** Font min 24pt, max 5 bullets per slide
3. **Screenshots:** Tambahkan border/shadow untuk clarity
4. **Annotations:** Gunakan arrow untuk highlight fitur
5. **Balance:** Jangan terlalu banyak text, fokus visual

### **Presentation Tips:**
- **Duration:** 12-15 menit + 5 menit Q&A
- **Practice:** Rehearse untuk smooth flow
- **Backup:** Simpan PDF version
- **Demo:** Test koneksi sebelum presentasi
- **Confidence:** Pahami setiap fitur yang dibuat

---

## 📦 DELIVERABLES CHECKLIST

- [x] Source Code (GitHub)
- [x] Live Demo (https://bengkels.web.app)
- [x] APK File (app-release.apk)
- [x] Screenshots (60 screenshots organized)
- [x] Documentation (README + SCREENSHOT_GUIDE)
- [x] Presentation Slides (25 slides)
- [x] Firebase Console Access
- [x] Test Credentials

---

**Good Luck dengan Presentasi! 🎉**
