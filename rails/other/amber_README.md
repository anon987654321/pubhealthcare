# Amber - Complete Fashion Platform with StyleTailor AI Integration

Amber is an AI-enhanced social network for fashion that implements the complete StyleTailor PDF concepts with a multi-agent AI loop, hierarchical feedback systems, and affiliate-as-style-component integration. Built with Rails 8+ standards and modern web technologies.

## Core StyleTailor Features

### Multi-Agent AI Loop (Designer → Consultant → Critic → Selector)
- **Designer Agent**: Creates initial outfit suggestions based on wardrobe analysis
- **Consultant Agent**: Provides styling advice and refinements with Marie Kondo principles  
- **Critic Agent**: Evaluates with hierarchical feedback (item/outfit/try-on levels)
- **Selector Agent**: Final selection with personas-aware heuristics (mobile, power user, beginner, accessibility)

### Style Consistency Scoring
- VQAScore-like style consistency calculation
- Color harmony analysis with complementary/analogous color theory
- Brand compatibility assessment
- IQA (Image Quality Assessment) integration ready
- Face similarity scoring for try-on predictions

### Affiliate-as-Style-Component (Not Just Ads)
- **Amazon Integration**: Ferrum-based scraper for personalized fashion recommendations
- **Tradedoubler API**: Norwegian local fashion alternatives via tradedoubler.no
- **Adaptive Feed Insertion**: Context-aware affiliate suggestions based on user personas
- **Privacy-First**: All affiliate features are opt-in via environment variables

## Fashion Platform Features

### Wardrobe Organization (Marie Kondo Style)
- **Visualize Your Wardrobe**: Photo organization with AI categorization
- **Joy Rating System**: 0-10 scale for each item with emotional tracking
- **Wear Tracking**: Cost-per-wear calculations and usage analytics
- **Declutter Suggestions**: AI-powered recommendations for unused/low-joy items
- **CSV Import/Export**: Complete wardrobe data portability

### Style Assistant & Outfit Composition
- **AI-Powered Daily Suggestions**: Context-aware outfit recommendations
- **Mix & Match Magic**: Intelligent combination algorithms
- **Occasion-Based Styling**: Work, casual, date, workout outfit planning
- **Weather Integration**: Climate-appropriate clothing suggestions
- **Body Type Awareness**: Flattering style recommendations

### Social & Community Features
- **Fashion Feed**: Personalized content with adaptive affiliate insertion
- **Live Chat**: Real-time styling discussions
- **Community Feedback**: Outfit rating and advice sharing
- **Style Challenges**: Gamified fashion competitions
- **Inspiration Library**: Save and organize style ideas

## Technical Architecture

### Rails 8+ Modern Stack
- **Framework**: Rails 8.0.0 with Hotwire/Turbo integration
- **Real-time**: StimulusReflex + Cable Ready for live updates
- **Frontend**: Modern Stimulus controllers with stimulus-components.com
- **Database**: PostgreSQL with optimized fashion data schema
- **Background**: Redis for caching and real-time features

### AI & ML Integration
- **LangChain.rb**: Multi-LLM orchestration (OpenAI, Replicate)
- **Replicate**: Image analysis, style transfer, and color analysis models
- **Ferrum**: Headless browser automation for affiliate product scraping
- **Style Scoring**: Advanced algorithms for outfit compatibility

### Privacy & Performance
- **Zero-Trust**: No hardcoded secrets, environment-based configuration
- **Opt-in Features**: AI and affiliate features disabled by default
- **WCAG Compliance**: Accessibility-first design patterns
- **Mobile Optimized**: Responsive design with mobile-specific personas

## Setup Instructions

### Prerequisites
- Ruby 3.3.0+
- Node.js 20+
- PostgreSQL 13+
- Redis 6+

### Basic Installation
```bash
# Clone and setup
git clone <repository>
cd amber
bundle install

# Database setup
bin/rails db:setup

# Start server
bin/rails server
```

### AI Features (Optional)
```bash
# Enable AI features
export ENABLE_AI_FEATURES=true
export OPENAI_API_KEY=your_key_here
# OR
export REPLICATE_API_TOKEN=your_token_here

# Verify AI integration
bin/rails amber:verify_concepts
```

### Affiliate Integration (Optional)
```bash
# Enable affiliate features
export ENABLE_AFFILIATE_FEATURES=true
export AMAZON_AFFILIATE_ID=your_id_here
export TRADEDOUBLER_API_KEY=your_key_here

# Test affiliate integration
bin/rails console
> Affiliate::AmazonScraper.new.search_fashion_items("blue dress")
```

## Personas-Aware Heuristics

### Mobile Users
- **Priority**: Convenience, comfort
- **Time Limit**: 30 seconds
- **Interface**: Minimal, swipe-friendly
- **Affiliate Frequency**: Low, non-intrusive

### Power Users  
- **Priority**: Sophistication, uniqueness
- **Time Limit**: 120 seconds
- **Interface**: Detailed analytics, advanced filters
- **Affiliate Frequency**: Medium, detailed recommendations

### Beginners
- **Priority**: Simplicity, guidance  
- **Time Limit**: 60 seconds
- **Interface**: Guided tours, educational content
- **Affiliate Frequency**: High, educational focus

### Accessibility Users
- **Priority**: Comfort, practicality
- **Time Limit**: 45 seconds  
- **Interface**: High contrast, screen reader optimized
- **Affiliate Frequency**: Low, explicit consent required

## Quality Gates & Standards

### Security: ≥9.5/10
- Zero-trust architecture
- No hardcoded secrets
- Environment-based configuration
- OWASP compliance

### Accessibility: ≥7.0/10  
- WCAG 2.1 AA compliance
- Screen reader optimization
- Keyboard navigation
- High contrast support

### Performance: ≥7.0/10
- Fast feed loading (<2s)
- Optimized database queries
- CDN-ready asset pipeline
- Redis caching strategy

### UX: ≥7.5/10
- Nielsen Norman Group principles
- Intuitive navigation
- Mobile-first design
- Persona-aware interfaces

### Maintainability: ≥8.0/10
- Clean, documented code
- Modular architecture
- Comprehensive test coverage
- Automated integrity checks

## Environment Variables

### Core Configuration
```bash
# Database
DATABASE_URL=postgresql://...
REDIS_URL=redis://...

# AI Features (Optional)
ENABLE_AI_FEATURES=false
OPENAI_API_KEY=sk-...
REPLICATE_API_TOKEN=r8_...

# Affiliate Features (Optional)  
ENABLE_AFFILIATE_FEATURES=false
AMAZON_AFFILIATE_ID=your-20
TRADEDOUBLER_API_KEY=...

# Application
SECRET_KEY_BASE=...
RAILS_ENV=production
```

## API Documentation

### StyleTailor AI Endpoints
```ruby
# Generate style recommendations
POST /api/v1/style/recommendations
{
  "occasion": "work",
  "weather": "cold", 
  "preferences": {"style": "minimalist"}
}

# Get affiliate suggestions
GET /api/v1/affiliate/recommendations?local=true

# Real-time wardrobe updates
WebSocket: /cable (WardrobeReflex, StyleRecommendationReflex)
```

### Webhook Integration
```ruby
# Style consistency scoring
POST /webhooks/style_score
{
  "outfit_id": 123,
  "items": [{"id": 1, "color": "blue"}, ...]
}
```

## Development & Testing

### Run Tests
```bash
# Full test suite
bin/rails test

# AI integration tests
bin/rails test test/services/ai/

# Affiliate integration tests  
bin/rails test test/services/affiliate/
```

### Concept Integrity Verification
```bash
# Verify StyleTailor implementation
bin/rails amber:verify_concepts

# Generate sample recommendations
bin/rails amber:sample_recommendations
```

### Development Tools
```bash
# Start development server with hot reload
bin/rails server

# Real-time CSS/JS compilation
bin/rails assets:precompile

# Database migrations
bin/rails db:migrate
```

## Deployment

### Production Checklist
- [ ] Environment variables configured
- [ ] Database migrated
- [ ] Assets precompiled  
- [ ] Redis configured
- [ ] SSL certificates installed
- [ ] Background jobs configured
- [ ] Monitoring setup

### Container Deployment
```dockerfile
# Dockerfile provided for containerized deployment
FROM ruby:3.3.0
# ... (optimized for production)
```

## Monitoring & Analytics

### Fashion Analytics Dashboard
- Wardrobe utilization metrics
- Style preference evolution
- Joy rating trends
- Cost-per-wear optimization
- Declutter success tracking

### AI Performance Metrics
- Recommendation accuracy
- User satisfaction scores
- Agent processing times
- Style consistency scores
- Persona classification accuracy

## Contributing

### Code Standards
- Follow Rails 8+ conventions
- Use descriptive commit messages
- Write comprehensive tests
- Document new features
- Maintain concept integrity

### StyleTailor Compliance
All changes must maintain fidelity to StyleTailor PDF concepts:
- Multi-agent AI workflow preservation
- Hierarchical feedback structure integrity  
- Style consistency scoring accuracy
- Persona-aware heuristics functionality
- Affiliate-as-style-component philosophy

## Support & Documentation

### Troubleshooting
- Check environment variables
- Verify API keys and tokens
- Review Rails logs
- Run integrity checks
- Consult persona guidelines

### Advanced Configuration
- Custom LLM providers
- Additional affiliate networks
- Style scoring algorithm tuning
- Persona behavior modification
- Feed insertion optimization

## License & Credits

Built with inspiration from StyleTailor research and implemented with modern Rails 8+ standards. Maintains privacy-first principles with opt-in AI and affiliate features.

**Framework Compliance**: v37.3.2
**Rails Version**: 8.0.0+  
**Architecture**: Multi-agent AI with affiliate integration
**Privacy Level**: Opt-in, user-controlled
