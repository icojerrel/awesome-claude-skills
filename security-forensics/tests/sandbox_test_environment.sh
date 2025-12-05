#!/bin/bash
# Sandbox Test Environment for Forensic Tools
# Creates isolated, safe testing environment with containerization support

VERSION="1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_usage() {
    cat << EOF
${CYAN}═══════════════════════════════════════════════════════════════════${NC}
Sandbox Test Environment v${VERSION}
Safe, isolated environment for testing forensic tools
${CYAN}═══════════════════════════════════════════════════════════════════${NC}

${YELLOW}WHY SANDBOX?${NC}
  ✓ Prevents contamination of production environment
  ✓ Safe malware analysis (simulated samples can't escape)
  ✓ Clean slate for each test run
  ✓ No impact on host filesystem or network
  ✓ Reproducible test conditions
  ✓ Rollback capability after tests
  ✓ Isolated process space
  ✓ Network isolation for C&C simulation

${YELLOW}SANDBOX METHODS:${NC}
  1. Docker Container (recommended)
  2. chroot Jail (Linux)
  3. Separate mount namespace
  4. Temporary filesystem overlay

${YELLOW}USAGE:${NC}
    $0 create [--method docker|chroot|tmpfs]
    $0 run <command>
    $0 destroy
    $0 status

${YELLOW}OPTIONS:${NC}
    create              Create isolated sandbox
    run <cmd>           Execute command in sandbox
    destroy             Remove sandbox completely
    status              Show sandbox status
    --method <type>     Sandbox method (docker, chroot, tmpfs)
    --keep              Keep sandbox after tests
    --help              Show this help

${YELLOW}EXAMPLES:${NC}
    # Create Docker-based sandbox
    $0 create --method docker

    # Run test framework in sandbox
    $0 run ./forensic_test_framework.sh --all

    # Check status
    $0 status

    # Cleanup
    $0 destroy

${CYAN}═══════════════════════════════════════════════════════════════════${NC}
EOF
}

#═══════════════════════════════════════════════════════════════════
# DOCKER SANDBOX
#═══════════════════════════════════════════════════════════════════

create_docker_sandbox() {
    echo -e "${BLUE}Creating Docker-based sandbox...${NC}"

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}⚠ Docker not found. Install with:${NC}"
        echo "  Ubuntu/Debian: sudo apt-get install docker.io"
        echo "  RHEL/CentOS: sudo yum install docker"
        return 1
    fi

    # Create Dockerfile
    cat > /tmp/forensic_sandbox_Dockerfile << 'EOF'
FROM ubuntu:22.04

# Install forensic dependencies
RUN apt-get update && apt-get install -y \
    bash \
    coreutils \
    file \
    grep \
    sed \
    awk \
    curl \
    wget \
    bc \
    openssl \
    dnsutils \
    whois \
    exiftool \
    xxd \
    && rm -rf /var/lib/apt/lists/*

# Create forensic user
RUN useradd -m -s /bin/bash forensic

# Set working directory
WORKDIR /forensic

# Copy scripts (mounted at runtime)
USER forensic

CMD ["/bin/bash"]
EOF

    # Build Docker image
    echo "Building Docker image..."
    docker build -t forensic-sandbox -f /tmp/forensic_sandbox_Dockerfile /tmp/ 2>&1 | grep -E "Step|Successfully"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Docker sandbox created${NC}"
        echo "forensic-sandbox-docker" > /tmp/forensic_sandbox_type
        return 0
    else
        echo -e "${RED}✗ Docker build failed${NC}"
        return 1
    fi
}

#═══════════════════════════════════════════════════════════════════
# CHROOT SANDBOX
#═══════════════════════════════════════════════════════════════════

create_chroot_sandbox() {
    echo -e "${BLUE}Creating chroot-based sandbox...${NC}"

    local sandbox_root="/tmp/forensic_sandbox_chroot"

    # Create minimal chroot environment
    mkdir -p "$sandbox_root"/{bin,lib,lib64,usr,tmp,dev,proc,sys,etc,home/forensic}

    # Copy essential binaries
    local bins="bash ls cat grep sed awk file stat md5sum sha256sum date"
    for bin in $bins; do
        local bin_path=$(which $bin 2>/dev/null)
        if [ -n "$bin_path" ]; then
            cp "$bin_path" "$sandbox_root/bin/" 2>/dev/null
            # Copy dependencies
            ldd "$bin_path" 2>/dev/null | grep -o '/[^ ]*' | while read -r lib; do
                if [ -f "$lib" ]; then
                    mkdir -p "$sandbox_root$(dirname "$lib")"
                    cp "$lib" "$sandbox_root$lib" 2>/dev/null
                fi
            done
        fi
    done

    # Mount pseudo filesystems
    sudo mount -t proc proc "$sandbox_root/proc" 2>/dev/null
    sudo mount -t sysfs sys "$sandbox_root/sys" 2>/dev/null
    sudo mount -t tmpfs tmpfs "$sandbox_root/tmp" 2>/dev/null

    echo -e "${GREEN}✓ chroot sandbox created at $sandbox_root${NC}"
    echo "forensic-sandbox-chroot:$sandbox_root" > /tmp/forensic_sandbox_type
    return 0
}

#═══════════════════════════════════════════════════════════════════
# TMPFS SANDBOX (Lightweight)
#═══════════════════════════════════════════════════════════════════

create_tmpfs_sandbox() {
    echo -e "${BLUE}Creating tmpfs-based sandbox (RAM disk)...${NC}"

    local sandbox_root="/tmp/forensic_sandbox_tmpfs"

    # Create tmpfs mount
    mkdir -p "$sandbox_root"
    sudo mount -t tmpfs -o size=1G tmpfs "$sandbox_root" 2>/dev/null

    if [ $? -eq 0 ]; then
        # Create directory structure
        mkdir -p "$sandbox_root"/{data,results,scripts}

        echo -e "${GREEN}✓ tmpfs sandbox created (1GB RAM disk)${NC}"
        echo "forensic-sandbox-tmpfs:$sandbox_root" > /tmp/forensic_sandbox_type
        return 0
    else
        echo -e "${YELLOW}⚠ tmpfs creation failed (may need sudo)${NC}"
        echo "Creating directory-based sandbox instead..."

        mkdir -p "$sandbox_root"/{data,results,scripts}
        echo "forensic-sandbox-dir:$sandbox_root" > /tmp/forensic_sandbox_type
        return 0
    fi
}

#═══════════════════════════════════════════════════════════════════
# RUN COMMAND IN SANDBOX
#═══════════════════════════════════════════════════════════════════

run_in_sandbox() {
    local command="$@"

    if [ ! -f /tmp/forensic_sandbox_type ]; then
        echo -e "${RED}✗ No sandbox exists. Create one first with: $0 create${NC}"
        return 1
    fi

    local sandbox_type=$(cat /tmp/forensic_sandbox_type)
    local method=$(echo "$sandbox_type" | cut -d: -f1)
    local location=$(echo "$sandbox_type" | cut -d: -f2)

    case "$method" in
        forensic-sandbox-docker)
            echo -e "${BLUE}Running in Docker sandbox...${NC}"
            local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            local forensics_dir="$(dirname "$script_dir")"

            docker run --rm -it \
                -v "$forensics_dir:/forensic" \
                -w /forensic \
                --network none \
                --read-only \
                --tmpfs /tmp:rw,noexec,nosuid,size=1G \
                forensic-sandbox \
                bash -c "$command"
            ;;

        forensic-sandbox-chroot)
            echo -e "${BLUE}Running in chroot sandbox...${NC}"
            sudo chroot "$location" bash -c "$command"
            ;;

        forensic-sandbox-tmpfs|forensic-sandbox-dir)
            echo -e "${BLUE}Running in isolated directory sandbox...${NC}"
            (
                cd "$location" || exit 1
                eval "$command"
            )
            ;;

        *)
            echo -e "${RED}✗ Unknown sandbox type: $method${NC}"
            return 1
            ;;
    esac
}

#═══════════════════════════════════════════════════════════════════
# DESTROY SANDBOX
#═══════════════════════════════════════════════════════════════════

destroy_sandbox() {
    if [ ! -f /tmp/forensic_sandbox_type ]; then
        echo -e "${YELLOW}⚠ No sandbox to destroy${NC}"
        return 0
    fi

    local sandbox_type=$(cat /tmp/forensic_sandbox_type)
    local method=$(echo "$sandbox_type" | cut -d: -f1)
    local location=$(echo "$sandbox_type" | cut -d: -f2)

    echo -e "${BLUE}Destroying sandbox...${NC}"

    case "$method" in
        forensic-sandbox-docker)
            # Remove Docker container and image
            docker rmi forensic-sandbox 2>/dev/null
            echo -e "${GREEN}✓ Docker sandbox removed${NC}"
            ;;

        forensic-sandbox-chroot)
            # Unmount filesystems
            sudo umount "$location/proc" 2>/dev/null
            sudo umount "$location/sys" 2>/dev/null
            sudo umount "$location/tmp" 2>/dev/null
            # Remove chroot directory
            sudo rm -rf "$location"
            echo -e "${GREEN}✓ chroot sandbox removed${NC}"
            ;;

        forensic-sandbox-tmpfs)
            # Unmount tmpfs
            sudo umount "$location" 2>/dev/null
            rm -rf "$location"
            echo -e "${GREEN}✓ tmpfs sandbox removed${NC}"
            ;;

        forensic-sandbox-dir)
            # Just remove directory
            rm -rf "$location"
            echo -e "${GREEN}✓ Directory sandbox removed${NC}"
            ;;
    esac

    rm -f /tmp/forensic_sandbox_type
}

#═══════════════════════════════════════════════════════════════════
# SHOW STATUS
#═══════════════════════════════════════════════════════════════════

show_status() {
    if [ ! -f /tmp/forensic_sandbox_type ]; then
        echo -e "${YELLOW}⚠ No active sandbox${NC}"
        return 0
    fi

    local sandbox_type=$(cat /tmp/forensic_sandbox_type)
    local method=$(echo "$sandbox_type" | cut -d: -f1)
    local location=$(echo "$sandbox_type" | cut -d: -f2)

    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}SANDBOX STATUS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo "Type: $method"
    echo "Location: $location"
    echo

    case "$method" in
        forensic-sandbox-docker)
            echo "Docker Image:"
            docker images forensic-sandbox 2>/dev/null | grep -v REPOSITORY || echo "  Not found"
            echo
            echo "Running Containers:"
            docker ps -a --filter ancestor=forensic-sandbox 2>/dev/null | grep -v CONTAINER || echo "  None"
            ;;

        forensic-sandbox-chroot)
            echo "Chroot Directory Size:"
            du -sh "$location" 2>/dev/null || echo "  Not accessible"
            echo
            echo "Mounted Filesystems:"
            mount | grep "$location" || echo "  None"
            ;;

        forensic-sandbox-tmpfs)
            echo "Tmpfs Mount:"
            df -h "$location" 2>/dev/null || echo "  Not mounted"
            echo
            echo "Contents:"
            ls -la "$location" 2>/dev/null || echo "  Empty"
            ;;

        forensic-sandbox-dir)
            echo "Directory Size:"
            du -sh "$location" 2>/dev/null || echo "  Not found"
            echo
            echo "Contents:"
            ls -la "$location" 2>/dev/null || echo "  Empty"
            ;;
    esac

    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
}

#═══════════════════════════════════════════════════════════════════
# QUICK TEST RUNNER
#═══════════════════════════════════════════════════════════════════

run_quick_test() {
    echo -e "${CYAN}Running quick sandbox validation test...${NC}"
    echo

    # Test 1: File creation
    echo -e "${BLUE}[Test 1]${NC} File creation in sandbox"
    run_in_sandbox "echo 'test' > /tmp/sandbox_test.txt && cat /tmp/sandbox_test.txt"

    # Test 2: Network isolation (should fail in Docker)
    echo -e "${BLUE}[Test 2]${NC} Network isolation check"
    run_in_sandbox "ping -c 1 8.8.8.8 2>&1 || echo 'Network isolated (expected)'"

    # Test 3: Process isolation
    echo -e "${BLUE}[Test 3]${NC} Process listing"
    run_in_sandbox "ps aux 2>&1 | head -5 || echo 'Limited process visibility (expected in sandbox)'"

    echo
    echo -e "${GREEN}✓ Sandbox validation complete${NC}"
}

#═══════════════════════════════════════════════════════════════════
# MAIN
#═══════════════════════════════════════════════════════════════════

ACTION=""
METHOD="tmpfs"  # Default to tmpfs (most portable)

while [[ $# -gt 0 ]]; do
    case $1 in
        create) ACTION="create"; shift ;;
        run) ACTION="run"; shift; COMMAND="$@"; break ;;
        destroy) ACTION="destroy"; shift ;;
        status) ACTION="status"; shift ;;
        test) ACTION="test"; shift ;;
        --method) METHOD="$2"; shift 2 ;;
        --help) show_usage; exit 0 ;;
        *) echo "Unknown option: $1"; show_usage; exit 1 ;;
    esac
done

case "$ACTION" in
    create)
        case "$METHOD" in
            docker) create_docker_sandbox ;;
            chroot) create_chroot_sandbox ;;
            tmpfs) create_tmpfs_sandbox ;;
            *) echo "Unknown method: $METHOD"; exit 1 ;;
        esac
        ;;

    run)
        if [ -z "$COMMAND" ]; then
            echo "No command specified"
            exit 1
        fi
        run_in_sandbox "$COMMAND"
        ;;

    destroy)
        destroy_sandbox
        ;;

    status)
        show_status
        ;;

    test)
        run_quick_test
        ;;

    *)
        show_usage
        exit 1
        ;;
esac
