#!/bin/bash

# install.sh - Install Claude Code skills and agents
# Usage: ./install.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Target directories
CLAUDE_DIR="$HOME/.claude"
SKILLS_TARGET="$CLAUDE_DIR/skills"
AGENTS_TARGET="$CLAUDE_DIR/agents"

# Source directories (relative to script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SOURCE="$SCRIPT_DIR/skills"
AGENTS_SOURCE="$SCRIPT_DIR/agents"

# Counters
installed=0
skipped=0
overwritten=0

print_header() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}       Claude Code Skills & Agents Installer${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_summary() {
    echo ""
    echo -e "${BLUE}──────────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo -e "  ${GREEN}✓ Installed:${NC}   $installed"
    echo -e "  ${YELLOW}⟳ Overwritten:${NC} $overwritten"
    echo -e "  ${RED}✗ Skipped:${NC}     $skipped"
    echo ""
    echo -e "${BLUE}Locations:${NC}"
    echo -e "  Skills: $SKILLS_TARGET"
    echo -e "  Agents: $AGENTS_TARGET"
    echo ""
    echo -e "${YELLOW}⚠  IMPORTANT:${NC} If you have Claude Code running, exit and restart"
    echo -e "   your session for the new skills/agents to take effect."
    echo ""
    echo -e "   Run ${GREEN}/exit${NC} or press ${GREEN}Ctrl+C${NC} to end your current session."
    echo ""
}

# Ask user for confirmation
# Returns 0 for yes, 1 for no
confirm() {
    local prompt="$1"
    local response
    
    while true; do
        echo -en "${YELLOW}$prompt [y/n/a]: ${NC}"
        read -r response
        case "$response" in
            [yY]|[yY][eE][sS]) return 0 ;;
            [nN]|[nN][oO]) return 1 ;;
            [aA]|[aA][lL][lL]) return 2 ;;  # Yes to all
            *) echo "Please answer y (yes), n (no), or a (all)" ;;
        esac
    done
}

# Install a single file
# Args: $1 = source file, $2 = target directory, $3 = type (skill/agent)
install_file() {
    local source_file="$1"
    local target_dir="$2"
    local file_type="$3"
    local filename=$(basename "$source_file")
    local target_file="$target_dir/$filename"
    
    # Check if target exists
    if [[ -f "$target_file" ]]; then
        # Compare files
        if cmp -s "$source_file" "$target_file"; then
            echo -e "  ${GREEN}✓${NC} $filename (already up to date)"
            ((skipped++))
            return 0
        fi
        
        # File exists and is different
        if [[ "$OVERWRITE_ALL" == "true" ]]; then
            cp "$source_file" "$target_file"
            echo -e "  ${YELLOW}⟳${NC} $filename (overwritten)"
            ((overwritten++))
            return 0
        fi
        
        echo ""
        echo -e "  ${YELLOW}!${NC} $filename already exists and differs"
        echo -e "    Target: $target_file"
        
        # Show diff summary
        local diff_lines=$(diff "$target_file" "$source_file" | wc -l)
        echo -e "    Changes: ~$diff_lines lines different"
        
        confirm "  Overwrite existing $file_type?" 
        local result=$?
        
        if [[ $result -eq 0 ]]; then
            cp "$source_file" "$target_file"
            echo -e "  ${YELLOW}⟳${NC} $filename (overwritten)"
            ((overwritten++))
        elif [[ $result -eq 2 ]]; then
            OVERWRITE_ALL="true"
            cp "$source_file" "$target_file"
            echo -e "  ${YELLOW}⟳${NC} $filename (overwritten)"
            ((overwritten++))
        else
            echo -e "  ${RED}✗${NC} $filename (skipped)"
            ((skipped++))
        fi
    else
        # New file, just copy
        cp "$source_file" "$target_file"
        echo -e "  ${GREEN}✓${NC} $filename (installed)"
        ((installed++))
    fi
}

# Install all files from a directory
# Args: $1 = source dir, $2 = target dir, $3 = type (skill/agent), $4 = extension
install_directory() {
    local source_dir="$1"
    local target_dir="$2"
    local file_type="$3"
    local extension="$4"
    
    # Check if source directory exists
    if [[ ! -d "$source_dir" ]]; then
        echo -e "${YELLOW}No $file_type directory found at $source_dir${NC}"
        return 0
    fi
    
    # Count files
    local file_count=$(find "$source_dir" -maxdepth 1 -name "*$extension" -type f 2>/dev/null | wc -l)
    
    if [[ $file_count -eq 0 ]]; then
        echo -e "${YELLOW}No $file_type files found in $source_dir${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Installing ${file_type}s ($file_count found):${NC}"
    echo ""
    
    # Create target directory if needed
    mkdir -p "$target_dir"
    
    # Process each file
    for file in "$source_dir"/*"$extension"; do
        [[ -f "$file" ]] || continue
        install_file "$file" "$target_dir" "$file_type"
    done
    
    echo ""
}

# Handle skill directories (folders with SKILL.md)
install_skill_directories() {
    local source_dir="$1"
    local target_dir="$2"
    
    # Check if source directory exists
    if [[ ! -d "$source_dir" ]]; then
        return 0
    fi
    
    # Find skill directories (contain SKILL.md)
    for skill_dir in "$source_dir"/*/; do
        [[ -d "$skill_dir" ]] || continue
        
        local skill_name=$(basename "$skill_dir")
        local skill_file="$skill_dir/SKILL.md"
        
        if [[ -f "$skill_file" ]]; then
            local target_skill_dir="$target_dir/$skill_name"
            
            echo -e "${BLUE}Installing skill: $skill_name${NC}"
            
            if [[ -d "$target_skill_dir" ]]; then
                if [[ "$OVERWRITE_ALL" == "true" ]]; then
                    rm -rf "$target_skill_dir"
                    cp -r "$skill_dir" "$target_skill_dir"
                    echo -e "  ${YELLOW}⟳${NC} $skill_name/ (overwritten)"
                    ((overwritten++))
                else
                    confirm "  Skill '$skill_name' exists. Overwrite?"
                    local result=$?
                    
                    if [[ $result -eq 0 ]]; then
                        rm -rf "$target_skill_dir"
                        cp -r "$skill_dir" "$target_skill_dir"
                        echo -e "  ${YELLOW}⟳${NC} $skill_name/ (overwritten)"
                        ((overwritten++))
                    elif [[ $result -eq 2 ]]; then
                        OVERWRITE_ALL="true"
                        rm -rf "$target_skill_dir"
                        cp -r "$skill_dir" "$target_skill_dir"
                        echo -e "  ${YELLOW}⟳${NC} $skill_name/ (overwritten)"
                        ((overwritten++))
                    else
                        echo -e "  ${RED}✗${NC} $skill_name/ (skipped)"
                        ((skipped++))
                    fi
                fi
            else
                mkdir -p "$target_dir"
                cp -r "$skill_dir" "$target_skill_dir"
                echo -e "  ${GREEN}✓${NC} $skill_name/ (installed)"
                ((installed++))
            fi
            echo ""
        fi
    done
}

# Main
main() {
    print_header
    
    # Check if ~/.claude exists
    if [[ ! -d "$CLAUDE_DIR" ]]; then
        echo -e "${YELLOW}Creating $CLAUDE_DIR directory...${NC}"
        mkdir -p "$CLAUDE_DIR"
        echo ""
    fi
    
    # Global flag for "overwrite all"
    OVERWRITE_ALL="false"
    
    # Install agents (.md files)
    install_directory "$AGENTS_SOURCE" "$AGENTS_TARGET" "agent" ".md"
    
    # Install skills (can be .md files or directories with SKILL.md)
    install_directory "$SKILLS_SOURCE" "$SKILLS_TARGET" "skill" ".md"
    install_skill_directories "$SKILLS_SOURCE" "$SKILLS_TARGET"
    
    print_summary
}

# Run main
main "$@"
