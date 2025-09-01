# ❓ CrypticDash Frequently Asked Questions

## 🔐 Authentication & Setup

### Q: How do I get started with CrypticDash?
**A:** Download the app, sign in with your GitHub account using OAuth or a Personal Access Token, and start adding repositories to monitor.

### Q: What's the difference between OAuth and Personal Access Token?
**A:** 
- **OAuth** (recommended): Secure, no token management, automatic refresh
- **Personal Access Token**: Manual token generation, more control, requires manual renewal

### Q: What GitHub permissions does CrypticDash need?
**A:** CrypticDash requires:
- `repo` - Full repository access (read/write)
- `read:user` - Read user profile information

### Q: Can I use CrypticDash with private repositories?
**A:** Yes! As long as your authentication method has access to the private repositories, CrypticDash can work with them.

### Q: What if my GitHub token expires?
**A:** You'll need to generate a new Personal Access Token and update it in the app settings, or switch to OAuth authentication.

## 📱 App Usage

### Q: How do I add a new project to monitor?
**A:** Tap the **+** button (floating action button) on the dashboard, browse your repositories, and select the ones you want to monitor.

### Q: Can I remove projects from the dashboard?
**A:** Yes! Open the project details and scroll to the bottom to find the "Remove Project from App" button.

### Q: How do I search for specific projects?
**A:** Use the search bar at the top of the dashboard to find projects by name.

### Q: What do the different project statuses mean?
**A:** 
- **Connected**: Project is syncing properly with GitHub
- **Disconnected**: Project has sync issues or connection problems

### Q: How do I refresh project data?
**A:** Pull down on the dashboard (mobile) or click the refresh button on individual projects.

## ✅ To-Do Management

### Q: How do I add new To-Do items?
**A:** In project details, click "Add To-Do", enter a title, optional notes, and select a category.

### Q: Can I edit existing To-Do items?
**A:** Currently, you can toggle completion status and add notes. Full editing is planned for future versions.

### Q: How do I mark a To-Do as complete?
**A:** Simply tap on any unchecked To-Do item to mark it complete, or tap a completed item to mark it pending.

### Q: What are the different To-Do categories?
**A:** Categories include: Current Progress, Next Steps, Roadmap, Features, Bug Fixes, Documentation, Testing, and Deployment.

### Q: Do To-Do changes sync automatically?
**A:** Yes! All changes are automatically saved to GitHub in real-time.

### Q: What happens if I lose internet connection?
**A:** Changes are cached locally and will sync when connection is restored. You'll see a sync indicator during offline periods.

## 🎨 Customization

### Q: How do I switch between light and dark themes?
**A:** Go to Settings and toggle the theme switch. The app will remember your preference.

### Q: Can I customize the dashboard layout?
**A:** Currently, the layout is fixed, but customization options are planned for future versions.

### Q: How do I change the app language?
**A:** Language support is planned for future versions. Currently, the app is English-only.

## 🔮 AI Features

### Q: What are AI Insights?
**A:** AI Insights provide intelligent analysis of your projects, including progress analysis, next steps recommendations, and task prioritization.

### Q: How do I enable AI features?
**A:** AI features are automatically enabled for all users. No setup required!

### Q: What AI models does CrypticDash use?
**A:** CrypticDash uses local AI models (Gemma 3 270M IT) for privacy and offline functionality.

### Q: Is my data sent to external AI services?
**A:** No! All AI processing happens locally on your device using the built-in models.

## 📱 Platform Support

### Q: What platforms does CrypticDash support?
**A:** CrypticDash works on:
- **Mobile**: Android (5.0+) and iOS (11.0+)
- **Desktop**: Windows 10+, macOS 10.14+, and Linux (Ubuntu 18.04+)
- **Web**: Modern browsers with Progressive Web App support

### Q: Can I use the same data across multiple devices?
**A:** Yes! Your project data is stored on GitHub, so you can access it from any device where you're signed in.

### Q: Is there a web version?
**A:** Yes! CrypticDash works in web browsers and can be installed as a Progressive Web App.

### Q: Do I need to install anything on my computer?
**A:** For mobile and desktop apps, you'll need to install the app. For web, just visit the website in your browser.

## 🔒 Privacy & Security

### Q: Where is my data stored?
**A:** All data is stored on GitHub in your repositories. CrypticDash only caches data locally on your device.

### Q: Does CrypticDash have access to my code?
**A:** CrypticDash only reads To-Do files and repository metadata. It cannot access your source code.

### Q: Are my GitHub credentials secure?
**A:** Yes! Credentials are stored locally on your device and encrypted. They're never sent to external servers.

### Q: Can CrypticDash modify my repositories?
**A:** CrypticDash can only modify To-Do files in repositories you've explicitly selected. It cannot modify any other files.

## 🚨 Troubleshooting

### Q: The app won't start. What should I do?
**A:** Try restarting the app, clearing app cache, or reinstalling. Check the Troubleshooting Guide for more detailed steps.

### Q: Projects aren't loading. How do I fix this?
**A:** Check your internet connection, verify GitHub access, refresh the dashboard, or re-authenticate.

### Q: To-Do changes aren't saving. What's wrong?
**A:** Check your GitHub write permissions, verify the repository exists, and ensure you have internet connectivity.

### Q: The app is slow or crashes frequently. How can I improve performance?
**A:** Close unused projects, limit the number of monitored repositories, and ensure your device has sufficient storage and memory.

### Q: I'm getting authentication errors. What should I do?
**A:** Check your GitHub token permissions, regenerate the token if needed, or try OAuth authentication instead.

## 🔄 Data & Sync

### Q: How often does CrypticDash sync with GitHub?
**A:** CrypticDash syncs in real-time when you make changes, and also performs background syncs periodically.

### Q: What happens if I edit To-Dos from multiple devices?
**A:** Changes are synced automatically. If there are conflicts, the most recent change typically wins.

### Q: Can I export my project data?
**A:** Data export features are planned for future versions. Currently, all data is accessible through GitHub.

### Q: What if I accidentally delete a project from CrypticDash?
**A:** No worries! The repository still exists on GitHub. You can simply add it back to CrypticDash.

### Q: How do I backup my data?
**A:** Your data is automatically backed up on GitHub. You can also manually backup To-Do files from your repositories.

## 🆕 Features & Updates

### Q: How often is CrypticDash updated?
**A:** Updates are released regularly with new features, bug fixes, and improvements.

### Q: Can I request new features?
**A:** Yes! Please create an issue on the GitHub repository with your feature request.

### Q: Is there a roadmap for future features?
**A:** Yes! Check the project documentation for planned features and development roadmap.

### Q: Can I contribute to CrypticDash development?
**A:** Absolutely! CrypticDash is open source. Check the Contributing Guide for information on how to get involved.

## 💰 Pricing & Licensing

### Q: Is CrypticDash free to use?
**A:** Yes! CrypticDash is completely free and open source.

### Q: Are there any usage limits?
**A:** Usage is limited only by GitHub's API rate limits and your repository access permissions.

### Q: Can I use CrypticDash for commercial projects?
**A:** Yes! CrypticDash is licensed under the MIT License, which allows commercial use.

### Q: Is there a premium version with additional features?
**A:** Currently, all features are free. Premium features may be added in the future.

## 🆘 Getting Help

### Q: Where can I get help if I have problems?
**A:** Check the User Guide, Troubleshooting Guide, or create an issue on the GitHub repository.

### Q: Is there a community or forum for CrypticDash?
**A:** The GitHub repository serves as the main community hub for discussions and support.

### Q: Can I report bugs?
**A:** Yes! Please report bugs by creating an issue on the GitHub repository with detailed information.

### Q: How do I stay updated on CrypticDash news?
**A:** Watch the GitHub repository for releases, updates, and announcements.

---

**Still have questions?** Check the other documentation files or create an issue on the GitHub repository for additional support.
