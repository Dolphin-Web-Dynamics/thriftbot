# 🛍️ ThriftBot

A modern inventory management system built for online resellers, featuring AI-powered product descriptions, multi-platform listing management, and comprehensive sales analytics.

[![Ruby](https://img.shields.io/badge/Ruby-4.0.1-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.2-red.svg)](https://rubyonrails.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## ✨ Features

### 📦 Inventory Management
- **SKU-based tracking** with detailed product attributes (brand, category, size, condition, materials)
- **Multi-image support** with Active Storage (front, back, measurements, tags, imperfections)
- **Status workflow**: Draft → Listed → Sold/Archived/Donated
- **Advanced search & filtering** powered by Ransack
- **Bulk CSV import/export** for efficient data management

### 🤖 AI-Powered Content
- **OpenAI integration** for generating product descriptions
- **Platform-optimized titles** (Shopify, Depop, Poshmark, etc.)
- **Automated pricing suggestions** based on comparable items
- **Background job processing** with Solid Queue

### 🏪 Multi-Platform Listings
- Manage listings across **7+ platforms**: Depop, Vinted, Shopify, Poshmark, Grailed, Mercari, eBay
- **Platform-specific pricing** with automatic multipliers (lower/mid/higher tier)
- **Bulk listing status management** (draft, active, paused, sold, delisted)
- **Automatic delisting** when items sell on any platform

### 📊 Sales Analytics
- **Real-time dashboard** with revenue, profit, and inventory metrics
- **Interactive charts** (sales by platform, monthly trends, profit margins)
- **Profit tracking** with acquisition cost vs. revenue analysis
- **Platform performance comparison**
- **12-month historical data** visualization

### 💾 Data Management
- **Automated SQLite backups** to Backblaze B2 (daily at 3 AM UTC)
- **One-command restore** from cloud backups
- **CSV import service** with error handling and validation
- **Audit trail** for AI generations and status changes

## 🛠️ Tech Stack

### Backend
- **Ruby 4.0.1** - Latest Ruby with performance improvements
- **Rails 8.1.2** - Modern Rails with Solid Queue, Solid Cache, and Solid Cable
- **SQLite3** - Lightweight, serverless database
- **Puma** - High-performance web server

### Frontend
- **Hotwire** (Turbo + Stimulus) - SPA-like experience without JavaScript frameworks
- **Tailwind CSS** - Utility-first styling
- **Importmap** - Zero-build JavaScript management
- **Chartkick** - Beautiful charts with minimal code

### Infrastructure
- **Kamal** - Docker-based deployment to any server
- **Thruster** - HTTP/2 proxy with asset caching
- **Backblaze B2** - Cost-effective cloud backup storage
- **Let's Encrypt** - Automatic SSL certificates

### Key Gems
- `ruby-openai` - AI content generation
- `ransack` - Advanced search and filtering
- `pagy` - Fast, lightweight pagination
- `groupdate` - Time-series data grouping
- `aws-sdk-s3` - S3-compatible backup storage

## 🚀 Getting Started

### Prerequisites
- Ruby 4.0.1
- SQLite3
- Node.js (for asset compilation)

### Installation

```bash
# Clone the repository
git clone https://github.com/Dolphin-Web-Dynamics/thriftbot.git
cd thriftbot

# Install dependencies
bundle install

# Setup database
bin/rails db:setup

# Start the server
bin/dev
```

Visit `http://localhost:3000`

### Configuration

#### OpenAI API (Optional)
```bash
# Add your OpenAI API key to credentials
bin/rails credentials:edit

# Add:
openai:
  api_key: your_api_key_here
```

#### Backblaze B2 Backups (Optional)
```bash
bin/rails credentials:edit

# Add:
backblaze:
  endpoint: https://s3.us-west-004.backblazeb2.com
  region: us-west-004
  bucket: your-bucket-name
  key_id: your_key_id
  application_key: your_application_key
```

## 📝 Usage

### Import Inventory from CSV
```bash
# Via web interface: /csv_imports/new
# Or programmatically:
bin/rails runner "CsvImportService.new(csv_import, 'path/to/file.csv').call"
```

### Generate AI Descriptions
1. Navigate to an item's detail page
2. Click "Generate AI Content"
3. Review and edit the generated description
4. Save to apply

### Create Listings
1. From item page, click "New Listing"
2. Select platform and set price
3. Mark as active when ready to publish
4. System suggests prices based on platform tier

### Record Sales
1. Click "Record Sale" on item page
2. Select platform and enter sale details
3. System automatically:
   - Marks item as sold
   - Delists other platform listings
   - Calculates profit and margins

### Backup & Restore
```bash
# Manual backup
bin/rails db:backup

# List available backups
bin/rails db:backup_list

# Restore from backup
bin/rails db:restore[filename.sqlite3]
```

## 🚢 Deployment

### Deploy with Kamal
```bash
# Initial setup
bin/kamal setup

# Deploy updates
bin/kamal deploy

# View logs
bin/kamal logs

# Access console
bin/kamal console
```

### Environment Variables
Set in `config/deploy.yml`:
- `RAILS_MASTER_KEY` - Rails credentials encryption key
- `ADMIN_EMAIL` - Admin user email
- `ADMIN_PASSWORD` - Admin user password

## 📊 Database Schema

### Core Models
- **Item** - Inventory items with full product details
- **Listing** - Platform-specific listings with pricing
- **Sale** - Completed sales with revenue tracking
- **Brand/Category/Source** - Organizational taxonomies
- **Platform** - Marketplace configurations
- **CsvImport** - Bulk import tracking
- **AiGeneration** - AI content generation history

## 🔒 Security

- **Brakeman** - Static security analysis
- **Bundler Audit** - Dependency vulnerability scanning
- **RuboCop** - Code quality and style enforcement
- **bcrypt** - Secure password hashing
- **SSL/TLS** - Automatic HTTPS via Let's Encrypt

## 🧪 Testing

```bash
# Run all tests
bin/rails test

# Run system tests
bin/rails test:system

# Run security scans
bin/brakeman
bin/bundler-audit

# Run linter
bin/rubocop
```

## 📈 Performance

- **Solid Queue** - Background jobs without Redis
- **Solid Cache** - Database-backed caching
- **Eager loading** - Optimized N+1 queries
- **Pagy pagination** - Minimal memory footprint
- **Asset fingerprinting** - Efficient browser caching

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Rails 8](https://rubyonrails.org/)
- Deployed with [Kamal](https://kamal-deploy.org/)
- AI powered by [OpenAI](https://openai.com/)
- Styled with [Tailwind CSS](https://tailwindcss.com/)

## 📧 Contact

Project Link: [https://github.com/Dolphin-Web-Dynamics/thriftbot](https://github.com/Dolphin-Web-Dynamics/thriftbot)

Live Demo: [https://thriftbot.smelltherosessecondhand.com](https://thriftbot.smelltherosessecondhand.com)
