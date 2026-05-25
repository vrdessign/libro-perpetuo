# Libro Perpetuo — WebXR PoC v1.0
## Complete Deployment Guide

**Dessign Innovation | Cristian Dessì | May 2026**

---

## What's in this Package

```
LibroPerpetuo_WebXR_PoC.html  ← Main app (single file, self-contained)
manifest.json                 ← PWA manifest
compile_targets.py            ← SVG→PNG→.mind compiler script
supabase_schema.sql           ← Backend DB schema + demo data
README.md                     ← This file

/pages_svg/                   ← 100 crypto-punk border SVGs (from previous step)
/pages_png/                   ← Generated PNGs (output of compile_targets.py)
/targets/
  pages.mind                  ← Compiled MindAR target file (generate manually)
  target_index.json           ← Page number mapping (auto-generated)
```

---

## How It Works

```
Physical book (crypto-punk border)
        ↓
XREAL Eye camera reads 3-sided border pattern
        ↓
MindAR Image Tracking (browser, no install)
        ↓
Matched to target index → page number decoded
        ↓
Supabase API: GET /content/{titleId}/{pageNum}
        ↓
Content overlay displayed on screen
(Three.js plane anchored to page surface)
```

---

## Step 1: Compile MindAR Targets

The `.mind` file is the compiled database of all 100 page images. MindAR uses it to match camera frames in real time.

### Option A: Online Compiler (Recommended for PoC)

1. Go to: **https://hiukim.github.io/mind-ar-js-doc/tools/compile**
2. Upload all 100 `page_NNN.png` files (from `/pages_png/`)
3. Click "Compile"
4. Download `targets.mind`
5. Rename to `pages.mind`
6. Place in `/targets/pages.mind`

### Option B: CLI Compiler

```bash
# Install
npm install -g mind-ar

# Convert SVGs to PNG first
python3 compile_targets.py

# Compile targets
npx mind-ar-image-compiler \
  pages_png/page_001.png \
  pages_png/page_002.png \
  ... (all 100) \
  --output targets/pages.mind
```

---

## Step 2: Connect Supabase (Optional for PoC)

The PoC works fully offline with built-in demo content. To connect real cloud content:

1. Create a project at **https://supabase.com**

2. Run the schema:
   ```
   Supabase Dashboard → SQL Editor → Paste supabase_schema.sql → Run
   ```

3. In `LibroPerpetuo_WebXR_PoC.html`, update the config section:
   ```javascript
   const SUPABASE_URL = 'https://your-project.supabase.co';
   const SUPABASE_ANON_KEY = 'your-anon-key';
   ```

4. Uncomment the Supabase fetch in `getContent()`:
   ```javascript
   const { data } = await supabase
     .from('pages')
     .select('chapter_title, text_content, image_url')
     .eq('title_id', titleId)
     .eq('page_number', pageNum)
     .single();
   ```

---

## Step 3: Deploy

### Netlify (Recommended — free tier)

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy from folder
netlify deploy --prod --dir .

# Or drag-and-drop the folder at:
# https://app.netlify.com/drop
```

Your app will be live at `https://your-site.netlify.app`

### Vercel

```bash
npm install -g vercel
vercel --prod
```

### Self-hosted (HTTPS required for camera API)

```bash
# Local HTTPS for development
npx serve --ssl-cert cert.pem --ssl-key key.pem .

# Or use ngrok for quick external access
ngrok http 443
```

**IMPORTANT**: Camera API requires HTTPS. HTTP localhost works for development.

---

## Step 4: Test on XREAL

### Setup
1. Connect XREAL One Pro + XREAL Eye + XREAL Beam Pro
2. On Beam Pro, open **Chrome** browser
3. Navigate to your deployed URL
4. Allow camera permission when prompted
5. Point camera at a page of the Neutral Book

### Expected Behaviour
- **Splash screen** → Loading animation → AR session starts
- **Scan guide** → Gold corner brackets guide alignment
- **Tracking active** → Gold dot pulses, "Page NNN detected"
- **Content overlay** → Text appears anchored to page surface
- **Turn page** → Content updates in ~100ms

### Demo Mode (no hardware)
1. Open app in any browser with a camera
2. Tap **⊞** button (grid icon) in top right
3. Select any page number from the grid
4. Content for that page loads immediately

---

## Device Compatibility

| Device | Browser | Status |
|--------|---------|--------|
| XREAL One Pro + Beam Pro | Chrome Android | ✅ Primary target |
| Meta Quest 2/3 | Meta Browser | ✅ Full WebXR |
| HoloLens 2 | Edge | ✅ Supported |
| Android phone (any) | Chrome 81+ | ✅ Full AR |
| iPhone (iOS 16+) | Safari | ⚠️ Limited |
| Desktop + webcam | Chrome | ✅ Dev/demo |

---

## Adding Real Content

### Add a title to the demo database

In `LibroPerpetuo_WebXR_PoC.html`, find `DEMO_LIBRARY` and add:

```javascript
{
  id: "my_book",
  title: "My Book Title",
  author: "Author Name",
  slot: 250,         // 100, 250, 500, 750, or 1000
  totalPages: 187,
  language: "en"
}
```

Then add page content to `DEMO_CONTENT`:

```javascript
"my_book": {
  1: { chapter: "Chapter 1", text: "First page content..." },
  2: { chapter: "Chapter 1", text: "Second page content..." },
  // ...
}
```

---

## Production Upgrade Checklist

- [ ] Compile `pages.mind` from all 100 page PNGs
- [ ] Set up Supabase project and run schema
- [ ] Configure SUPABASE_URL and SUPABASE_ANON_KEY
- [ ] Add authentication (Supabase Auth)
- [ ] Implement DRM (row-level security per user)
- [ ] Add Stripe payment integration for title purchase
- [ ] Build companion PWA for title selection
- [ ] Deploy to Netlify/Vercel with custom domain
- [ ] Test on XREAL One Pro + Eye + Beam Pro

---

## Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| Tracking latency | < 30ms | From page visible to overlay |
| Content load | < 200ms | With caching |
| Page change detection | < 300ms | With debounce |
| App cold start | < 3s | Including camera init |
| Frame rate | 30+ FPS | MindAR optimised |

---

## Troubleshooting

**Camera not working**
- Ensure HTTPS (required for camera API)
- Check browser permissions (Settings → Site permissions → Camera)
- Try Chrome 81+ on Android

**MindAR not loading**
- Check browser console for CDN errors
- Try: `https://cdn.jsdelivr.net/npm/mind-ar@1.2.5/dist/mindar-image-three.prod.js`
- Fallback: download and host locally

**Tracking unstable**
- Ensure good lighting on the book page
- Print page borders at minimum 200 DPI
- Avoid shiny/glossy paper (causes reflections)
- Hold book steady — don't tilt more than 45°

**Content not loading**
- Check SUPABASE_URL and key
- Enable CORS in Supabase dashboard
- Check network tab for 401/403 errors

---

## Architecture Notes

The PoC uses a **hybrid overlay** approach:
- **MindAR** handles camera access and image tracking
- **Three.js** creates an anchored 3D plane on the detected page
- **CSS overlay** renders the actual text content (better typography than Three.js textures)
- The CSS overlay is positioned at the center of the screen when a page is tracked, giving the visual impression of text on the page

For production, the Three.js plane will render text directly as a texture using `CanvasTexture`, enabling true AR occlusion and perspective-correct text rendering.

---

## Contact

**Cristian Dessì** — Dessign Innovation
commerciale@tourvirtuale.digital
www.dessigninnovation.com

*Libro Perpetuo WebXR PoC v1.0 — Confidential*
