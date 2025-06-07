---
description: "Cursor Rules documentation với updates cho new script architecture"
---
# Cursor Rules - QLDSV-HTC Project

## 📋 Overview
Bộ rules được tối ưu hóa theo **Cursor Rules Best Practices** với format `.mdc` chuẩn, YAML frontmatter, và cấu trúc modular. Được tối ưu cho script architecture hiện tại với advanced tooling và cross-platform support.

## 🏗️ Rules Structure

### Always Applied Rules (alwaysApply: true)
- **00-project-context.mdc** - Context tổng quan và kiến trúc dự án
- **01-clean-code.mdc** - Clean code guidelines và coding standards  
- **02-terminal-commands.mdc** - Terminal command execution với script utilities
- **40-workflow.mdc** - Development workflow với script architecture

### Auto-Attached Rules (globs pattern)
- **05-environment.mdc** - Environment & config management với config-loader.sh
- **10-database.mdc** - SQL Server guidelines với database utilities
- **20-backend.mdc** - FastAPI backend patterns
- **30-frontend.mdc** - React frontend guidelines

### Agent Requested Rules (description only)
- **15-sql-optimization.mdc** - SQL performance tuning (khi cần optimize)
- **99-project-summary.mdc** - Project overview với architecture features

## 🔧 Script Architecture Features

### 1. **Script Management**
- **Component-based organization**: `scripts/setup/` và `scripts/utils/` theo be/db/fe
- **Cross-platform support**: Apple Silicon detection, platform-specific handling
- **Comprehensive health monitoring**: db-health-check.sh với detailed reports
- **Safety features**: Confirmation prompts, environment validation, root directory checks

### 2. **Enhanced Environment Management (05-environment.mdc)**
```bash
# New config loader patterns
source scripts/utils/config-loader.sh
load_env_file                    # Auto-detect .env files
validate_global_config           # Comprehensive validation
load_service_config "backend"    # Service-specific inheritance
```

### 3. **Updated Workflow Patterns (40-workflow.mdc)**
```bash
# New daily startup sequence
./scripts/start-database.sh --full-default-setup
./scripts/start-backend.sh --full-default-setup  
./scripts/start-frontend.sh --full-default-setup
./scripts/utils/db/db-health-check.sh
```

### 4. **Database Management Evolution (10-database.mdc)**
```bash
# Advanced database operations
./scripts/utils/db/start-db.sh           # Component isolation
./scripts/utils/db/reset-db.sh           # With confirmation
./scripts/utils/db/db-health-check.sh    # Comprehensive monitoring
```

### 5. **Terminal Commands Modernization (02-terminal-commands.mdc)**
- **Script-first approach**: Prioritize utility scripts over raw commands
- **Environment-aware**: Always load config before execution
- **Safety-focused**: Use confirmation prompts cho destructive operations

## ✅ New Architecture Benefits

### 1. **Developer Experience**
- **Quick start commands**: `./scripts/start-*.sh` với auto-setup
- **Health monitoring**: Comprehensive diagnostics với detailed reports
- **Cross-platform**: Apple Silicon support với automatic detection
- **Safety first**: Confirmation prompts cho destructive operations

### 2. **Operational Excellence**
- **Component isolation**: Database, backend, frontend scripts riêng biệt
- **Environment inheritance**: Root .env → component .env với validation
- **Advanced debugging**: Script output logs, health reports, diagnostics
- **Platform compatibility**: Windows/Linux/macOS với platform detection

### 3. **Script Management Features**
- **Root directory validation**: Scripts check execution context
- **Configuration validation**: Missing variables detection
- **Network management**: Docker network setup và management
- **Service lifecycle**: Start, stop, restart, reset, delete operations

## 🎯 Usage Patterns với New Architecture

### For AI Agent
- **Always rules** luôn có trong context với updated workflow patterns
- **Auto-attached** kích hoạt khi edit file matching globs với new script awareness
- **Agent-requested** AI tự fetch khi cần: `@15-sql-optimization` hoặc `@99-project-summary`

### For Developers
- **Modern workflow**: Script-first approach với comprehensive tooling
- **Safety mechanisms**: Confirmation prompts và validation checks
- **Health monitoring**: Regular health checks với detailed diagnostics
- **Cross-platform**: Seamless development trên các platform

## 📊 Before vs After Updates

| Aspect | Before | After |
|--------|--------|-------|
| **Scripts** | Basic script references | Comprehensive script architecture guide |
| **Environment** | Simple .env loading | Advanced config inheritance với validation |
| **Database** | Basic SQL guidelines | Full lifecycle management với health monitoring |
| **Workflow** | Generic development flow | Platform-specific, script-optimized workflow |
| **Commands** | Raw terminal commands | Script utilities với safety features |
| **Platform** | Generic cross-platform | Apple Silicon optimization, platform detection |

## 🚀 Key Features của Updated Rules

### Advanced Script Architecture Support
- **Component isolation** với separate setup/utils scripts
- **Environment management** với config-loader.sh patterns
- **Health monitoring** với comprehensive diagnostic tools
- **Safety features** với confirmation prompts và validation

### Cross-Platform Excellence
- **Apple Silicon support** với automatic Rosetta 2 setup
- **Platform detection** trong scripts cho optimal compatibility
- **Docker optimization** cho SQL Server trên Apple Silicon
- **Path handling** cho Windows/Linux/macOS

### Developer Productivity
- **Quick start sequences** với automated setup
- **Comprehensive health checks** cho early problem detection
- **Script-first debugging** với detailed output và diagnostics
- **Component-specific tools** cho focused development

## 📋 Next Steps
1. **Test updated rules** với real development scenarios sử dụng new script architecture
2. **Monitor AI behavior** với updated command patterns và script utilities
3. **Refine script guidance** based on usage patterns và developer feedback
4. **Add specialized rules** cho advanced script development patterns nếu cần

---
*Optimized theo Cursor Rules Best Practices v0.45+ với comprehensive new script architecture support* 