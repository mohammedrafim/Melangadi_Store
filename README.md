# 🏪 Melangadi Store - Stationery Management Mobile Application

A simple, modern, and user-friendly Flutter mobile application built specifically for stationery store owners to effortlessly manage **Products & Stock**, **Sales (Point of Sale)**, **Supplier Purchases**, and **Daily Financials**.

---

## 📱 Features Overview

### 1. 🏠 Executive Dashboard
- **💰 Today's Total Sales**: Live aggregate of sales made today with transaction counts.
- **🛒 Today's Purchases**: Daily supplier expenditure tracking.
- **💵 Cash in Hand**: Real-time cash register balance (Starting cash + Cash sales - Cash purchases). Includes a manual adjust tool for drawer reconciliation.
- **📦 Available Products**: Total catalog item count and total units in stock.
- **📊 Today's & Overall Profit**: Instant calculation of realized profit (`Revenue - Cost of Goods Sold`) with a toggle between daily and lifetime profit.
- **⚠️ Low Stock Alerts**: Highlights stationery items whose stock has fallen below the safety threshold, with a 1-tap reorder shortcut.
- **⚡ Quick Actions**: Direct shortcuts to *New Sale*, *New Purchase*, and *Add Product*.
- **🕒 Recent Sales Feed**: Instant overview of the latest transactions.

### 2. 📋 Products & Stock Management
- View complete product inventory with stock levels and profit margins.
- **Instant Search & Filters**: Search by product name or category, with filters for *Low Stock*, *In Stock*, and *Out of Stock*.
- **Product Details**:
  - Product Name (e.g. *Classmate Spiral Notebook*, *Parker Vector Pen*)
  - Purchase Price (₹) & Selling Price (₹)
  - Margin & Percentage markup
  - Available Stock Quantity & Unit (`pcs`, `pack`, `box`, `set`, `bottle`, etc.)
  - Low Stock Alert Threshold
- **Quick Stepper**: Fast `+` / `-` stock counter on each product card for quick physical audits.
- **Add & Edit**: Responsive modal with input validation.

### 3. 🛍️ Sales Management (POS & History)
- **Point of Sale (POS) Cart**:
  - Visual product carousel and search picker.
  - Multi-item cart with live line-item pricing and stock quantity validation (prevents selling more than is physically in stock).
  - Automatic total bill calculation.
- **Payment Methods**:
  - 💵 **Cash**: Automatically increments Cash in Hand.
  - 📱 **UPI**: Digital payment recording.
  - 📒 **Credit (Khata)**: Tracks pay-later sales with customer name and contact.
- **Automatic Stock Deduction**: Subtracts sold items from stock immediately upon sale.
- **Digital Receipt**: Clean invoice breakdown showing invoice number, date, itemized prices, total, and profit.
- **Sales History**: Searchable list of past sales filtered by *Today* / *All Time* and payment methods.

### 4. 📦 Purchase Management (Supplier Orders)
- **Record Purchase**:
  - Supplier Name (with one-tap quick suggestions for popular brands: Navneet, Camlin, Doms, Faber-Castell, Luxor, Kangaro).
  - Product selection with auto-fill of the current cost price.
  - Quantity received and live total purchase calculation.
  - Payment Status: `Paid`, `Pending`, or `Partial`.
  - Payment Method: `Cash`, `UPI`, `Bank Transfer`, or `Cheque`.
- **Automatic Stock Increase**: Adds received units directly to product inventory upon recording.
- **Cash Register Sync**: Deducts from Cash in Hand if marked as Paid via Cash.
- **Purchase History**: Complete log of past supplier orders with invoice numbers and payment status tags.

### 5. 🎨 Modern & Clean UI
- Material 3 stationery-inspired theme with deep royal blue (`#1E3A8A`), emerald green (`#10B981`), amber (`#F59E0B`), and soft slate surfaces (`#F8FAFC`).
- Bottom Navigation Bar with 4 main tabs:
  - 🏠 **Dashboard**
  - 🛍️ **Sales**
  - 📦 **Purchase**
  - 📋 **Products**
- **Hive NoSQL Database**: High-speed, lightweight local binary database (`hive_flutter`) storing products, sales, purchases, and cash register data offline.
- Pre-populated with clean state (no demo products).

---

## 🚀 How to Run the Application

```bash
# Clone the repository
cd "melangadi_store"

# Get packages
flutter pub get

# Run on mobile device or emulator
flutter run
```

---

## 🧪 Testing

Run unit tests and widget tests:

```bash
flutter test
```
# Melangadi_Store
