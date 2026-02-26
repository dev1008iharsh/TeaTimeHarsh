# TeaTimeHarsh
## 🔐 Authentication & Home Flow
 
### ✨ Features

- Multi-provider authentication (Email, Google, Facebook, Apple)
- Secure credential handling via external configuration files
- Input validation for authentication forms
- Password reset support
- Smooth animated transition after successful login





### 🏠 Home Interface

<img width="927" height="476" alt="dev.iharsh1008" src="https://github.com/user-attachments/assets/664c08a1-36f5-46b8-97c7-fb9637839bc3" />

- Fully programmatic UIKit interface  
- Segmented filtering (All / Favorites / Visited / My Places)  
- Dynamic list rendering with local filtering  
- Leading & trailing swipe actions for quick operations  
- CRUD functionality for user-managed entries  
- Tab-based navigation structure  
- Location-aware entries with latitude & longitude coordinates  

### 💾 Data & Persistence

- Local persistence using Core Data  
- Offline-first data access from local storage  
- Fast retrieval without network dependency  
- Reduced API usage and improved performance  
- Consistent data availability across sessions  

### 🖼️ Media & Interaction

- Asynchronous image loading with memory & disk caching  
- Images downloaded once and reused from cache  
- Prevents repeated network requests for existing media  
- Smooth scrolling without flicker or UI blocking  
- Stable rendering with reuse-safe cell configuration  
- Smooth UI animations and transitions  
- Responsive Auto Layout across devices  






## ➕ Add Place — Media Upload Flow
 <img width="939" height="494" alt="dev.iharsh1008" src="https://github.com/user-attachments/assets/6ec659bb-675e-4aeb-b2d7-196927a65aa8" />
### ✨ Features

- Form-based place creation via floating action button  
- Map location selection with coordinate capture  
- Media uploads (images, videos, PDF documents)  
- Cloud storage upload with database link persistence  
- Upload progress tracking with percentage indicator  
- Automatic navigation to home list after submission  

### 📁 Media Processing

- Client-side media handling before upload  
- Video compression to optimized resolution (≈720p)  
- Support for multiple file types via custom handling  
- Asynchronous upload operations  

### 📊 Completion Logic

- Internal progress calculation based on media types  
  - Images → 20%  
  - Video → 60%  
  - PDF → 20%  

### 📝 Draft & Resume Support

- Selected media temporarily stored in local FileManager  
- Failed or interrupted uploads saved as draft  
- App detects unfinished uploads on next launch  
- Option to resume or discard pending submission  
- Resume restores all fields and media from local storage  
- Only incomplete files are uploaded on retry  
- Discard removes draft data from local storage  

### ⏳ Background Upload

- Upload continues when app moves to background  
- Background task support for uninterrupted transfers  
- Upload proceeds until system background time expires  
- Maintains progress state during app switching  

### 🔄 Data Integration

- Newly added entry appears instantly in home listing  
- Stored metadata includes media references and location data  


## 📍 Place Details — Media, Contact & Reviews

<img width="930" height="500" alt="dev.iharsh1008" src="https://github.com/user-attachments/assets/bdd839ed-592a-49d6-9158-73f22d65c4d0" />


### ✨ Core Features

- Comprehensive place information display  
- Favorite / visited state management  
- Owner attribution and metadata  
- Edit, share, and delete actions  

### 🖼️ Media Viewing

- Zoomable image viewer with gesture support  
- Full-screen video playback with interactive controls  
- Full-screen PDF viewer with zoom and navigation  
- Read-only media presentation  

### 📞 Contact & Communication

- Direct call initiation  
- WhatsApp messaging  
- SMS sending  
- FaceTime support  
- Save to contacts and copy number  
- System action sheet for communication options  

### ⭐ Reviews System

- Single review allowed per user  
- Rating input with star selection  
- Optional image and text feedback  
- Review list with aggregated ratings  

### 🗺️ Location & Navigation

- Embedded map with place marker  
- Tap to open external maps application  
- Deep linking for navigation from current location  

### ⚡ Interaction & UI

- Programmatic UIKit implementation  
- Modern sheet presentation for owner details  
- Smooth animations and transitions  
- Gesture-driven interactions across media components  


## 👤 Profile & Settings Module

<img width="986" height="513" alt="Screenshot 2026-02-26 at 9 58 42 PM" src="https://github.com/user-attachments/assets/40fa9b8c-8ca2-4cf3-9bc8-0961b59e1cb6" />

### ⚙️ Personal & App Settings

- Programmatic with storyboard UIKit settings interface  
- Structured sections for personal data and app preferences  
- Navigation-driven settings hierarchy  
- Access to Favorites, Visited places, and user-created entries  
- Language selection with localization support  
- Notification toggle with persistent state  
- Appearance configuration (system / light / dark)  
- Dynamic app icon switching via system APIs  

### 📝 Profile Editing

- Editable user profile with form-based validation  
- Avatar update with media picker integration  
- Persistent user data storage  
- Input handling and state management  

### 🆘 Support & Feedback

- In-app support request via system mail composer  
- Pre-filled device, OS version, and account metadata  
- User-entered issue description  

### 🔐 Account & Security

- Secure logout with session termination  
- Account deletion with password re-authentication  
- Compliance with backend re-verification requirements  
- Optional removal of user-generated content  
- Confirmation dialogs for destructive actions  

### ⚡ Implementation Details

- Fully programmatic with storyboard UIKit components  
- Adaptive layout across device sizes  
- Reusable settings cells and models  
- Smooth navigation transitions  
- State persistence across sessions  

## ☁️ Backend — Firebase Services Integration

 <img width="504" height="683" alt="dev.iharsh1008" src="https://github.com/user-attachments/assets/79204487-f9ff-4159-8d9b-581adbbf85bf" />


### 🔐 Authentication

- User authentication managed via Firebase Authentication  
- Supports multiple sign-in providers  
- Unique user identity maintained across services  

### 🗄️ Database (Cloud Firestore)

- NoSQL document-based database architecture  
- Data organized in collections and documents  
- Separate collections for users, places, and reviews  
- Logical relationships maintained via document references and IDs  
- User-specific data such as favorites and visited places stored independently  

### 📦 Storage

- Media assets stored in Firebase Cloud Storage  
- Structured folders for different content types  
  - Cover images  
  - Videos  
  - Review media  
  - Menu documents  
  - Profile images  

### 🔗 Media Linking

- Uploaded files return secure download URLs  
- URLs stored in Firestore documents  
- Enables lightweight database records with external media storage  

### 🔄 Data Relationships

- Place documents linked with review documents  
- User documents linked with activity data (favorites, visits)  
- Reference-based association instead of relational joins  

### ⚡ Architecture Benefits

- Scalable cloud backend  
- Real-time data synchronization capability  
- Efficient media handling without bloating database  
- Optimized for mobile-first applications  


## 🧠 Architecture & Implementation Summary

- Modular programmatic UIKit architecture with reusable components  
- Mix of programmatic UI and XIB/NIB-based reusable views  
- Centralized managers using singleton patterns  
- Utility layers built with static helpers, extensions, enums, and structs  
- Separation of Core Data entities and app domain models  
- Consistent theme system with centralized Theme Manager  
- Dynamic Light / Dark mode support  

## ☁️ Backend & Cloud Integration

- Firebase Authentication for secure user identity management  
- Cloud Firestore (NoSQL document database) for structured data storage  
- Firebase Cloud Storage for media asset management  
- Media upload pipeline with URL-based linking to database records  
- Reference-based relationships between users, places, and reviews  
- Scalable cloud architecture optimized for mobile workloads  
- Robust error handling for network and backend operations  

## 💾 Data & Persistence

- Offline-first design using Core Data for local storage  
- Automatic synchronization between local cache and cloud data  
- Fast retrieval without network dependency  
- Persistent user data across sessions  
- Conflict-safe updates and consistency management  

## ⚡ Performance & Optimization

- Optimized list rendering with reuse-safe configurations  
- Efficient image caching for memory and disk reuse  
- Dedicated image download manager  
- Video compression to optimized resolution (~720p)  
- Smooth animations with minimal UI blocking  
- Reduced network usage via caching strategies  

## 🎨 UI & Interaction

- Custom reusable UI components (labels, cells, popups, menus)  
- Consistent design system across the application  
- Custom transitions and animated state changes  
- Haptic feedback integration (light, medium, heavy)  
- Toast-style notifications with stacked presentation  
- Gesture-driven media viewer with zoom and pan  
- Media sharing and saving from preview  

## 📡 Networking & Upload Handling

- Network-aware operations with connectivity monitoring  
- Upload progress tracking with percentage indicators  
- Background-friendly upload support  
- Draft and resume functionality for interrupted uploads  
- Fault-tolerant media transfer pipeline  

## 🗺️ System Integration

- Custom location manager with permission handling  
- Graceful handling of revoked permissions  
- Deep linking to external map applications  
- In-app communication via system services  

## 🔐 Account & Settings

- Editable user profile and preferences  
- Dynamic app icon switching  
- Notification and appearance controls  
- Bulk deletion of user-generated data  
- Secure account deletion with re-authentication  
- Session termination and logout handling  

## 🆘 Support & Diagnostics

- Dedicated bug reporting interface  
- Screenshot attachment capability  
- Pre-filled device and environment details  
- Email-based support workflow  

## 📁 Media & Utilities

- PDF preview and document handling  
- Media storage with cloud synchronization  
- Local draft storage using FileManager  
- Separate helpers for image, video, and document processing  

## ✅ Reliability & Stability

- Comprehensive error handling across app layers  
- Graceful fallback for network failures  
- Consistent state management during interruptions  
- Optimized resource usage for smooth user experience  


