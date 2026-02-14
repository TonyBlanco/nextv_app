# NeXtv Website Template

Complete, production-ready website template for NeXtv IPTV Player application.

## � Deploy to Vercel (Quick Start)

The easiest way to deploy this website:

### Method 1: Using Vercel CLI (Recommended)

```bash
# Install Vercel CLI (one time)
npm install -g vercel

# Navigate to website directory
cd docs/web

# Login to your Vercel account
vercel login

# Deploy!
vercel --prod
```

### Method 2: Using the Deploy Script

```bash
cd docs/web
./deploy.sh
```

### Method 3: Using Vercel Dashboard

1. Go to [vercel.com](https://vercel.com)
2. Click "Add New..." → "Project"
3. Import your Git repository or drag the `docs/web` folder
4. Deploy! ✨

**Complete deployment guide**: See [DEPLOYMENT_VERCEL.md](DEPLOYMENT_VERCEL.md) for detailed instructions, troubleshooting, custom domains, and more.

---

## �📁 Structure

```
docs/web/
├── index.html              # Main homepage
├── css/
│   └── styles.css          # Complete styling system
├── js/
│   └── main.js             # JavaScript functionality
├── images/                 # Images and assets (add your own)
│   ├── logo.svg
│   ├── favicon.png
│   ├── app-screenshot.png
│   └── og-image.jpg
└── pages/                  # Additional pages
    ├── about.html
    ├── blog.html
    ├── contact.html
    ├── help.html
    └── ... (create as needed)
```

## 🚀 Features

### ✅ Implemented

- **Modern, Responsive Design**: Mobile-first, works on all devices
- **Clean Architecture**: Semantic HTML5, organized CSS, modular JavaScript
- **Cross-browser Compatible**: Chrome, Firefox, Safari, Edge
- **Accessibility**: WCAG 2.1 compliant, keyboard navigation, screen reader friendly
- **Performance Optimized**: Fast loading, lazy loading images, debounced events
- **SEO Optimized**: Semantic markup, meta tags, Open Graph tags
- **Interactive Components**:
  - Sticky navigation with scroll effects
  - Mobile hamburger menu
  - Pricing toggle (monthly/annual)
  - FAQ accordion
  - Video modal
  - Animated scroll effects
  - Smooth scrolling
  - Toast notifications

### 🎨 Design System

**Colors**:
- Primary: #1E3A8A (Deep Blue)
- Accent: #06B6D4 (Cyan)
- Gradients: Primary to Accent

**Typography**:
- Font: Inter (modern, clean sans-serif)
- Responsive sizing with clamp()

**Components**:
- Buttons (primary, secondary, outline)
- Cards (feature, platform, pricing)
- Navigation
- Footer
- Modals
- Forms

## 🛠 Setup Instructions

### 1. Prerequisites

None! Pure HTML, CSS, and JavaScript. No build tools required.

### 2. Add Your Assets

Replace placeholder content with your actual assets:

**Images** (`docs/web/images/`):
- `logo.svg` - Your logo (SVG recommended)
- `favicon.png` - Browser favicon (32x32 or 64x64)
- `app-screenshot.png` - App interface screenshot for hero section
- `og-image.jpg` - Social media preview image (1200x630)
- Add more as needed

**Content**:
- Update text in `index.html`
- Replace video URL in `playVideo()` function
- Update download links for each platform
- Customize colors in CSS variables if desired

### 3. Local Development

**Option 1: Simple HTTP Server**

```bash
cd docs/web
python3 -m http.server 8000
# Visit http://localhost:8000
```

**Option 2: VS Code Live Server**

1. Install "Live Server" extension
2. Right-click `index.html` → "Open with Live Server"

**Option 3: Node.js http-server**

```bash
npm install -g http-server
cd docs/web
http-server
```

### 4. Deployment

**Static Hosting (Recommended)**:

- **Netlify**: Drag & drop the `web` folder
- **Vercel**: Connect GitHub repo, auto-deploy
- **GitHub Pages**: Push to `gh-pages` branch
- **Cloudflare Pages**: Connect repo, auto-deploy
- **AWS S3 + CloudFront**: Upload to S3 bucket, enable static hosting

**Traditional Hosting**:
- Upload files via FTP to your web host
- Configure domain and SSL certificate

## 📝 Customization Guide

### Colors

Edit CSS variables in `css/styles.css`:

```css
:root {
    --primary: #1E3A8A;      /* Change your primary color */
    --accent: #06B6D4;       /* Change your accent color */
    /* ... more variables */
}
```

### Navigation

Add/remove menu items in `index.html`:

```html
<ul class="nav-links" id="navLinks">
    <li><a href="#features">Features</a></li>
    <li><a href="#pricing">Pricing</a></li>
    <!-- Add more items here -->
</ul>
```

### Pricing Plans

Update pricing in `index.html`:

```html
<div class="plan-price">
    <span class="price monthly-price">$9.99</span>  <!-- Update prices -->
    <span class="period">/month</span>
</div>
```

Prices automatically switch when user toggles monthly/annual.

### Download Links

Update platform links in `js/main.js`:

```javascript
const downloadLinks = {
    ios: 'https://apps.apple.com/app/nextv',         // Update
    android: 'https://play.google.com/...',           // Update
    // ... etc
};
```

### Video Demo

Replace YouTube video ID in `js/main.js`:

```javascript
function playVideo() {
    const video = document.getElementById('demoVideo');
    video.src = 'https://www.youtube.com/embed/YOUR_VIDEO_ID?autoplay=1';
    // ...
}
```

## 🔧 Advanced Customization

### Adding Analytics

**Google Analytics 4**:

Add before `</head>` in `index.html`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

**Facebook Pixel**:

```html
<!-- Facebook Pixel Code -->
<script>
  !function(f,b,e,v,n,t,s)
  {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
  n.callMethod.apply(n,arguments):n.queue.push(arguments)};
  if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
  n.queue=[];t=b.createElement(e);t.async=!0;
  t.src=v;s=b.getElementsByTagName(e)[0];
  s.parentNode.insertBefore(t,s)}(window, document,'script',
  'https://connect.facebook.net/en_US/fbevents.js');
  fbq('init', 'YOUR_PIXEL_ID');
  fbq('track', 'PageView');
</script>
```

### Adding Newsletter Form

Add to footer or create dedicated section:

```html
<form id="newsletterForm" onsubmit="handleNewsletterSignup(event)">
    <input type="email" placeholder="Enter your email" required>
    <button type="submit" class="btn-primary">Subscribe</button>
</form>
```

Update JavaScript:

```javascript
function handleNewsletterSignup(event) {
    event.preventDefault();
    const email = event.target.querySelector('input[type="email"]').value;
    
    fetch('https://your-api.com/newsletter', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email })
    })
    .then(response => response.json())
    .then(data => {
        showToast('Successfully subscribed!');
        event.target.reset();
    })
    .catch(error => {
        showToast('Something went wrong. Please try again.');
    });
}
```

### Adding Blog

Create `pages/blog.html` based on structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <!-- Same head as index.html -->
    <title>Blog - NeXtv</title>
</head>
<body>
    <!-- Same navbar -->
    
    <section class="blog">
        <div class="container">
            <h1>NeXtv Blog</h1>
            <div class="blog-grid">
                <!-- Blog posts here -->
            </div>
        </div>
    </section>
    
    <!-- Same footer -->
</body>
</html>
```

## 📱 Responsive Breakpoints

- **Mobile**: < 480px
- **Tablet**: 481px - 768px
- **Desktop Small**: 769px - 1024px
- **Desktop Large**: > 1024px

Test on various devices and browsers.

## ♿ Accessibility

**Built-in Features**:
- Semantic HTML elements
- ARIA labels on interactive elements
- Keyboard navigation support
- Focus visible styles
- Skip to content link
- Alt text for images (add your own)
- Color contrast ratio > 4.5:1

**Testing**:
- Use screen reader (NVDA, JAWS, VoiceOver)
- Test keyboard-only navigation
- Run Lighthouse audit in Chrome DevTools
- Use axe DevTools extension

## 🚀 Performance

**Optimization Tips**:

1. **Image Optimization**:
   - Use WebP format where supported
   - Compress images (TinyPNG, Squoosh)
   - Use appropriate sizes (srcset)

2. **Lazy Loading**:
   - Already implemented for images with `data-src`
   - Add `data-src` attribute to images you want lazy loaded

3. **Minification** (for production):
   ```bash
   # CSS
   npx cssnano css/styles.css css/styles.min.css
   
   # JavaScript
   npx terser js/main.js -o js/main.min.js
   ```

4. **CDN**: Host assets on CDN for faster global delivery

## 🔍 SEO Checklist

- ✅ Descriptive title tags
- ✅ Meta descriptions
- ✅ Open Graph tags
- ✅ Twitter Card tags
- ✅ Semantic HTML
- ✅ Alt text on images
- ✅ Fast loading speed
- ✅ Mobile-friendly
- ✅ SSL certificate (HTTPS)

**Add**:
- Sitemap.xml
- Robots.txt
- Schema.org structured data
- Canonical URLs

## 🐛 Browser Support

- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+
- ⚠️ IE 11 (not supported - use polyfills if needed)

## 📄 License

This template is part of the NeXtv project. Modify and use as needed for your project.

## 🆘 Support

For questions or issues:
- Email: support@nextv.app
- Website: https://nextv.app/help
- GitHub Issues: [link to your repo]

## 📚 Additional Resources

- [Web.dev Best Practices](https://web.dev/)
- [MDN Web Docs](https://developer.mozilla.org/)
- [A11y Project](https://www.a11yproject.com/)
- [Can I Use](https://caniuse.com/) - Browser compatibility

---

**Made with ❤️ for NeXtv**

Last Updated: February 14, 2026
