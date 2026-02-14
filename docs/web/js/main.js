// ========================================
// NeXtv Website JavaScript
// ========================================

// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', function() {
    initNavbar();
    initPricingToggle();
    initFAQ();
    initScrollAnimations();
    initSmoothScroll();
});

// ========================================
// Navbar Functionality
// ========================================
function initNavbar() {
    const navbar = document.getElementById('navbar');
    const menuToggle = document.getElementById('menuToggle');
    const navLinks = document.getElementById('navLinks');
    
    // Navbar scroll effect
    let lastScroll = 0;
    
    window.addEventListener('scroll', () => {
        const currentScroll = window.pageYOffset;
        
        // Add/remove scrolled class
        if (currentScroll > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
        
        lastScroll = currentScroll;
    });
    
    // Mobile menu toggle
    if (menuToggle && navLinks) {
        menuToggle.addEventListener('click', () => {
            navLinks.classList.toggle('active');
            menuToggle.classList.toggle('active');
            
            // Animate menu toggle icon
            const spans = menuToggle.querySelectorAll('span');
            if (menuToggle.classList.contains('active')) {
                spans[0].style.transform = 'rotate(45deg) translate(5px, 5px)';
                spans[1].style.opacity = '0';
                spans[2].style.transform = 'rotate(-45deg) translate(7px, -6px)';
            } else {
                spans[0].style.transform = 'none';
                spans[1].style.opacity = '1';
                spans[2].style.transform = 'none';
            }
        });
        
        // Close mobile menu when clicking outside
        document.addEventListener('click', (e) => {
            if (!menuToggle.contains(e.target) && !navLinks.contains(e.target)) {
                navLinks.classList.remove('active');
                menuToggle.classList.remove('active');
                
                const spans = menuToggle.querySelectorAll('span');
                spans[0].style.transform = 'none';
                spans[1].style.opacity = '1';
                spans[2].style.transform = 'none';
            }
        });
        
        // Close mobile menu when clicking a link
        const links = navLinks.querySelectorAll('a');
        links.forEach(link => {
            link.addEventListener('click', () => {
                navLinks.classList.remove('active');
                menuToggle.classList.remove('active');
                
                const spans = menuToggle.querySelectorAll('span');
                spans[0].style.transform = 'none';
                spans[1].style.opacity = '1';
                spans[2].style.transform = 'none';
            });
        });
    }
}

// ========================================
// Pricing Toggle (Monthly/Annual)
// ========================================
function initPricingToggle() {
    const toggleButtons = document.querySelectorAll('.toggle-btn');
    const monthlyPrices = document.querySelectorAll('.monthly-price');
    const annualPrices = document.querySelectorAll('.annual-price');
    const monthlyNotes = document.querySelectorAll('.monthly-note');
    const annualNotes = document.querySelectorAll('.annual-note');
    
    toggleButtons.forEach(button => {
        button.addEventListener('click', () => {
            const period = button.getAttribute('data-period');
            
            // Update active state
            toggleButtons.forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');
            
            // Show/hide prices
            if (period === 'monthly') {
                monthlyPrices.forEach(price => price.style.display = 'inline');
                annualPrices.forEach(price => price.style.display = 'none');
                monthlyNotes.forEach(note => note.style.display = 'block');
                annualNotes.forEach(note => note.style.display = 'none');
            } else {
                monthlyPrices.forEach(price => price.style.display = 'none');
                annualPrices.forEach(price => price.style.display = 'inline');
                monthlyNotes.forEach(note => note.style.display = 'none');
                annualNotes.forEach(note => note.style.display = 'block');
            }
        });
    });
}

// ========================================
// FAQ Accordion
// ========================================
function initFAQ() {
    const faqItems = document.querySelectorAll('.faq-item');
    
    faqItems.forEach(item => {
        const question = item.querySelector('.faq-question');
        
        question.addEventListener('click', () => {
            const isActive = item.classList.contains('active');
            
            // Close all other items
            faqItems.forEach(otherItem => {
                if (otherItem !== item) {
                    otherItem.classList.remove('active');
                }
            });
            
            // Toggle current item
            if (isActive) {
                item.classList.remove('active');
            } else {
                item.classList.add('active');
            }
        });
    });
}

// ========================================
// Video Modal
// ========================================
function playVideo() {
    const modal = document.getElementById('videoModal');
    const video = document.getElementById('demoVideo');
    
    // Set video source (replace with your actual YouTube video ID)
    video.src = 'https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1';
    
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closeVideo() {
    const modal = document.getElementById('videoModal');
    const video = document.getElementById('demoVideo');
    
    modal.classList.remove('active');
    video.src = '';
    document.body.style.overflow = 'auto';
}

// Close video with Escape key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeVideo();
    }
});

// Close video when clicking outside
document.getElementById('videoModal')?.addEventListener('click', (e) => {
    if (e.target.id === 'videoModal') {
        closeVideo();
    }
});

// ========================================
// Smooth Scroll
// ========================================
function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const href = this.getAttribute('href');
            
            // Skip if href is just "#"
            if (href === '#') {
                e.preventDefault();
                return;
            }
            
            const targetId = href.substring(1);
            const targetElement = document.getElementById(targetId);
            
            if (targetElement) {
                e.preventDefault();
                
                const navbarHeight = document.getElementById('navbar').offsetHeight;
                const targetPosition = targetElement.offsetTop - navbarHeight - 20;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
}

// ========================================
// Scroll Animations (Intersection Observer)
// ========================================
function initScrollAnimations() {
    const animatedElements = document.querySelectorAll('.feature-card, .platform-card, .pricing-card');
    
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '0';
                entry.target.style.transform = 'translateY(20px)';
                
                setTimeout(() => {
                    entry.target.style.transition = 'all 0.6s ease-out';
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }, 100);
                
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);
    
    animatedElements.forEach(el => {
        observer.observe(el);
    });
}

// ========================================
// Download Button Handler
// ========================================
function handleDownload(platform) {
    const downloadLinks = {
        ios: 'https://apps.apple.com/app/nextv',
        android: 'https://play.google.com/store/apps/details?id=com.nextv.app',
        windows: 'ms-windows-store://pdp/?productid=XXXXX',
        mac: 'https://apps.apple.com/app/nextv',
        linux: '/download/nextv-linux.AppImage',
        webos: 'https://www.lgappstv.com/nextv',
        web: 'https://app.nextv.tv'
    };
    
    const link = downloadLinks[platform];
    if (link) {
        window.open(link, '_blank');
    }
}

// ========================================
// Platform Detection
// ========================================
function detectPlatform() {
    const userAgent = navigator.userAgent.toLowerCase();
    
    if (/iphone|ipad|ipod/.test(userAgent)) {
        return 'ios';
    } else if (/android/.test(userAgent)) {
        return 'android';
    } else if (/mac/.test(userAgent) && !/iphone|ipad|ipod/.test(userAgent)) {
        return 'mac';
    } else if (/win/.test(userAgent)) {
        return 'windows';
    } else if (/linux/.test(userAgent)) {
        return 'linux';
    } else {
        return 'web';
    }
}

// ========================================
// Auto-suggest Download Platform
// ========================================
window.addEventListener('load', () => {
    const platform = detectPlatform();
    const downloadButtons = document.querySelectorAll('a[href="#download"]');
    
    downloadButtons.forEach(button => {
        button.addEventListener('click', (e) => {
            e.preventDefault();
            handleDownload(platform);
        });
    });
});

// ========================================
// Newsletter Signup
// ========================================
function handleNewsletterSignup(email) {
    // Replace with your actual newsletter API endpoint
    console.log('Newsletter signup:', email);
    
    // Example: Send to backend
    /*
    fetch('/api/newsletter', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email }),
    })
    .then(response => response.json())
    .then(data => {
        console.log('Success:', data);
        alert('Thank you for subscribing!');
    })
    .catch((error) => {
        console.error('Error:', error);
        alert('Something went wrong. Please try again.');
    });
    */
}

// ========================================
// Track Analytics Events
// ========================================
function trackEvent(category, action, label) {
    // Google Analytics 4
    if (typeof gtag !== 'undefined') {
        gtag('event', action, {
            'event_category': category,
            'event_label': label
        });
    }
    
    // Facebook Pixel
    if (typeof fbq !== 'undefined') {
        fbq('trackCustom', action, {
            category: category,
            label: label
        });
    }
    
    // Console log for debugging
    console.log('Event tracked:', category, action, label);
}

// Track button clicks
document.addEventListener('click', (e) => {
    const target = e.target.closest('a, button');
    if (!target) return;
    
    const text = target.textContent.trim();
    
    if (text.includes('Download') || text.includes('Get Started')) {
        trackEvent('Conversion', 'click_download', text);
    } else if (text.includes('Pricing') || text.includes('Buy')) {
        trackEvent('Conversion', 'click_pricing', text);
    } else if (target.closest('.social-links')) {
        trackEvent('Social', 'click_social', target.getAttribute('aria-label'));
    }
});

// ========================================
// Lazy Loading Images
// ========================================
if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.add('loaded');
                observer.unobserve(img);
            }
        });
    });
    
    document.querySelectorAll('img[data-src]').forEach(img => {
        imageObserver.observe(img);
    });
}

// ========================================
// Handle Form Submissions
// ========================================
document.querySelectorAll('form').forEach(form => {
    form.addEventListener('submit', (e) => {
        e.preventDefault();
        
        const formData = new FormData(form);
        const data = Object.fromEntries(formData.entries());
        
        console.log('Form submitted:', data);
        
        // Add your form submission logic here
        // Example: handleNewsletterSignup(data.email);
    });
});

// ========================================
// Copy to Clipboard
// ========================================
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        showToast('Copied to clipboard!');
    }).catch(err => {
        console.error('Failed to copy:', err);
    });
}

// ========================================
// Toast Notifications
// ========================================
function showToast(message, duration = 3000) {
    // Remove existing toasts
    const existingToast = document.querySelector('.toast');
    if (existingToast) {
        existingToast.remove();
    }
    
    // Create toast element
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.textContent = message;
    toast.style.cssText = `
        position: fixed;
        bottom: 20px;
        right: 20px;
        background: var(--gray-900);
        color: var(--white);
        padding: 1rem 1.5rem;
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow-xl);
        z-index: 10000;
        animation: slideInUp 0.3s ease-out;
    `;
    
    document.body.appendChild(toast);
    
    // Remove after duration
    setTimeout(() => {
        toast.style.animation = 'slideOutDown 0.3s ease-out';
        setTimeout(() => toast.remove(), 300);
    }, duration);
}

// Add toast animations to styles
const style = document.createElement('style');
style.textContent = `
    @keyframes slideInUp {
        from {
            transform: translateY(100%);
            opacity: 0;
        }
        to {
            transform: translateY(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOutDown {
        from {
            transform: translateY(0);
            opacity: 1;
        }
        to {
            transform: translateY(100%);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

// ========================================
// Performance Optimization
// ========================================

// Debounce function for scroll events
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Throttle function for resize events
function throttle(func, limit) {
    let inThrottle;
    return function(...args) {
        if (!inThrottle) {
            func.apply(this, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// Apply optimized event listeners
const optimizedScroll = debounce(() => {
    // Add debounced scroll handlers here
}, 100);

const optimizedResize = throttle(() => {
    // Add throttled resize handlers here
}, 200);

window.addEventListener('scroll', optimizedScroll);
window.addEventListener('resize', optimizedResize);

// ========================================
// Accessibility Improvements
// ========================================

// Skip to main content link
function addSkipLink() {
    const skipLink = document.createElement('a');
    skipLink.href = '#home';
    skipLink.className = 'skip-link';
    skipLink.textContent = 'Skip to main content';
    skipLink.style.cssText = `
        position: absolute;
        top: -40px;
        left: 0;
        background: var(--primary);
        color: white;
        padding: 8px;
        text-decoration: none;
        z-index: 100;
    `;
    
    skipLink.addEventListener('focus', () => {
        skipLink.style.top = '0';
    });
    
    skipLink.addEventListener('blur', () => {
        skipLink.style.top = '-40px';
    });
    
    document.body.insertBefore(skipLink, document.body.firstChild);
}

addSkipLink();

// ========================================
// Console Easter Egg
// ========================================
console.log('%c👋 Hello Developer!', 'font-size: 24px; font-weight: bold; color: #1E3A8A;');
console.log('%cLike what you see? We\'re hiring! Check out https://nextv.app/careers', 'font-size: 14px; color: #06B6D4;');
console.log('%cInterested in our API? Visit https://nextv.app/api', 'font-size: 14px; color: #10B981;');
