# Git Upload System for MultiSpace Cloner

এই প্রজেক্টে তিনটি automated git upload script রয়েছে যা আপনাকে সহজেই GitHub এ changes commit এবং push করতে সাহায্য করবে।

## 📁 Available Scripts

### 1. `git_upload.bat` - Full Featured Upload
**সবচেয়ে comprehensive script যা সব ধরনের error handling সহ কাজ করে।**

**Features:**
- ✅ Git availability check
- ✅ Repository validation
- ✅ Change detection
- ✅ Custom commit message support
- ✅ Auto-generated timestamp messages
- ✅ Detailed error messages
- ✅ Step-by-step progress indication

**Usage:**
```bash
# Double click করুন অথবা command prompt থেকে চালান
git_upload.bat
```

### 2. `quick_upload.bat` - Quick & Simple
**দ্রুত upload এর জন্য minimal interaction script।**

**Features:**
- ⚡ Fast execution
- 🕒 Auto timestamp commit messages
- 🎯 Minimal user interaction
- ✅ Basic error detection

**Usage:**
```bash
# Double click করুন অথবা command prompt থেকে চালান
quick_upload.bat
```

### 3. `git_manager.ps1` - Advanced PowerShell
**সবচেয়ে advanced script যা command line parameters support করে।**

**Features:**
- 🎨 Colorful output
- 📊 Detailed git status
- 🔧 Multiple operation modes
- 📝 Custom commit messages
- 🚀 Quick mode
- 📋 Status-only mode
- 💡 Help system

**Usage:**
```powershell
# Basic usage
.\git_manager.ps1

# Quick upload
.\git_manager.ps1 -Quick

# Custom commit message
.\git_manager.ps1 -Message "Added new features"

# Show git status only
.\git_manager.ps1 -Status

# Show help
.\git_manager.ps1 -Help
```

## 🚀 Quick Start Guide

### First Time Setup
1. নিশ্চিত করুন যে Git installed আছে
2. GitHub repository এর সাথে remote origin setup করুন:
   ```bash
   git remote add origin https://github.com/kajialsoad/multi-spaces.git
   ```

### Daily Usage
1. **Quick Upload:** `quick_upload.bat` double click করুন
2. **Custom Message:** `git_upload.bat` চালান এবং আপনার message লিখুন
3. **Advanced Options:** PowerShell এ `git_manager.ps1` ব্যবহার করুন

## 🛠️ Troubleshooting

### Common Issues:

**❌ "Git is not installed"**
- Solution: Git download করুন https://git-scm.com/

**❌ "This is not a git repository"**
- Solution: `git init` command চালান

**❌ "Failed to push to GitHub"**
- Check internet connection
- Verify GitHub credentials
- Ensure remote origin is set correctly:
  ```bash
  git remote -v
  git remote add origin https://github.com/username/repository.git
  ```

**❌ "Permission denied"**
- Setup SSH key অথবা personal access token ব্যবহার করুন
- GitHub credentials check করুন

## 📝 Script Comparison

| Feature | git_upload.bat | quick_upload.bat | git_manager.ps1 |
|---------|----------------|------------------|------------------|
| Error Handling | ✅ Full | ⚡ Basic | ✅ Advanced |
| Custom Messages | ✅ Yes | ❌ No | ✅ Yes |
| Status Display | ✅ Detailed | ❌ Minimal | ✅ Comprehensive |
| Speed | 🐌 Thorough | ⚡ Fast | 🚀 Flexible |
| User Interaction | 💬 Interactive | 🤖 Minimal | 🎛️ Configurable |
| Colors | ❌ No | ❌ No | ✅ Yes |
| Parameters | ❌ No | ❌ No | ✅ Yes |

## 🎯 Recommendations

- **Daily quick updates:** Use `quick_upload.bat`
- **Important commits:** Use `git_upload.bat` with custom messages
- **Advanced users:** Use `git_manager.ps1` with parameters
- **First-time users:** Start with `git_upload.bat` for guided experience

## 🔐 Security Notes

- Scripts শুধুমাত্র local repository এ কাজ করে
- কোনো sensitive information store করে না
- GitHub credentials system এর default authentication ব্যবহার করে
- সব operations reversible (git reset/revert দিয়ে undo করা যায়)

## 📞 Support

যদি কোনো সমস্যা হয়:
1. Error message carefully পড়ুন
2. Internet connection check করুন
3. Git credentials verify করুন
4. Repository permissions check করুন

---

**Happy Coding! 🚀**

*এই scripts গুলো MultiSpace Cloner project এর development workflow সহজ করার জন্য তৈরি করা হয়েছে।*