# GitHub Pages Setup for Still Moment

This directory contains the GitHub Pages website for Still Moment, providing a publicly accessible privacy policy required for App Store submission.

## 🌐 Website URLs

Once GitHub Pages is activated:
- **Privacy Policy**: https://stillmoment-app.github.io/stillmoment/privacy
- **Home Page**: https://stillmoment-app.github.io/stillmoment/

## 📋 How to Activate GitHub Pages

Follow these steps to activate GitHub Pages for this repository:

### 1. Go to Repository Settings

1. Navigate to your repository on GitHub: https://github.com/stillmoment-app/stillmoment
2. Click on **"Settings"** (gear icon in the repository menu)

### 2. Navigate to Pages Section

1. In the left sidebar, scroll down and click **"Pages"** (under "Code and automation")

### 3. Configure GitHub Pages

1. Under **"Source"**, select:
   - **Source**: `Deploy from a branch`
   - **Branch**: `main`
   - **Folder**: `/docs`
2. Click **"Save"**

### 4. Wait for Deployment

1. GitHub will automatically build and deploy your site (takes 1-2 minutes)
2. Refresh the Settings → Pages page to see the deployment status
3. Once deployed, you'll see a message: **"Your site is live at https://stillmoment-app.github.io/stillmoment/"**

### 5. Verify the Website

Visit these URLs to confirm everything works:
- Home: https://stillmoment-app.github.io/stillmoment/
- Privacy Policy: https://stillmoment-app.github.io/stillmoment/privacy

## 📁 Website Structure

```
docs/
├── README.md           # This file (setup instructions)
├── index.html          # Home page with app info and links
└── privacy.html        # Bilingual privacy policy (English/German)
```

## 🎨 Design

The website uses Still Moment's design language:
- **Colors**: Warm earth tones (Terracotta #D4876F, Warm Sand #F5E6D3)
- **Typography**: Apple system fonts (-apple-system, San Francisco)
- **Style**: Clean, minimal, accessible
- **Languages**: English/German toggle on privacy page

## ✅ Next Steps After Activation

Once GitHub Pages is live:

1. **Test the URLs**:
   - Visit https://stillmoment-app.github.io/stillmoment/privacy
   - Verify both English and German versions work
   - Check language toggle functionality

2. **Update App Store Connect**:
   - Go to App Store Connect
   - Navigate to your app's "App Information" section
   - Paste privacy policy URL: `https://stillmoment-app.github.io/stillmoment/privacy`

3. **Verify in APP_STORE_METADATA.md**:
   - Already updated with the correct URL
   - Located at: `docs/app-store/APP_STORE_METADATA.md`

## 🔧 Troubleshooting

### Pages Not Showing Up
- Wait 2-3 minutes after enabling GitHub Pages
- Check Settings → Pages for deployment status
- Ensure branch is `main` and folder is `/docs`

### 404 Error
- Verify the `docs/` folder exists in the `main` branch
- Confirm `index.html` and `privacy.html` are in the `docs/` folder
- Check GitHub Actions tab for any deployment errors

### Wrong Repository Name
- If your repository is not `stillmoment-app/stillmoment`, update the URLs in:
  - `docs/index.html` (GitHub link)
  - `docs/privacy.html` (GitHub link)
  - `docs/app-store/APP_STORE_METADATA.md`

## 📞 Support

If you have questions:
- **Email**: stillMoment@posteo.de
- **GitHub Issues**: https://github.com/stillmoment-app/stillmoment/issues

---

**Last Updated**: 2024-11-09
