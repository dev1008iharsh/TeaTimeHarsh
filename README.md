# TeaTimeHarsh
## 🔐 Authentication & Home Flow

<p align="center">
  <img src="assets/auth_home.png" width="750"/>
</p>

### ✨ Features

- Multi-provider authentication (Email, Google, Facebook, Apple)
- Secure credential handling via external configuration files
- Input validation for authentication forms
- Password reset support
- Smooth animated transition after successful login


<img width="927" height="476" alt="Screenshot 2026-02-26 at 7 09 58 PM" src="https://github.com/user-attachments/assets/664c08a1-36f5-46b8-97c7-fb9637839bc3" />


### 🏠 Home Interface

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


<img width="939" height="494" alt="Screenshot 2026-02-26 at 7 14 18 PM" src="https://github.com/user-attachments/assets/6ec659bb-675e-4aeb-b2d7-196927a65aa8" />



## ➕ Add Place — Media Upload Flow

<p align="center">
  <img src="assets/add_place_form.png" width="750"/>
</p>

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









