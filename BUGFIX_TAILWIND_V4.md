# Tailwind CSS v4 Fix

**Issue**: Frontend was crashing with CSS syntax errors when using `@apply` with custom colors.

**Error**:
```
CssSyntaxError: tailwindcss: Cannot apply unknown utility class `bg-background`
```

**Root Cause**: Tailwind CSS v4 has breaking changes with how `@apply` works in `@layer base`. Custom colors from the theme config weren't being recognized.

**Solution**: Replaced Tailwind's `@apply` directives with plain CSS in `app/globals.css`.

**Changes Made**:

### Before (broken):
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply bg-background text-text-primary antialiased;
  }
}
```

### After (working):
```css
@import "tailwindcss";

body {
  background-color: #0a0a0a;
  color: #ffffff;
  -webkit-font-smoothing: antialiased;
}
```

**Impact**: 
- Site now loads successfully
- All styling preserved
- Tailwind utility classes still work in components
- Only base/global styles use plain CSS

**Files Modified**:
- `app/globals.css` - Removed `@apply` directives, used plain CSS for base styles

**Status**: ✅ Fixed - dev server running on http://localhost:3000

---

**Time Fixed**: 2026-01-31 21:10 PST  
**Fixed by**: Milo 🦊
