// Article 1 — native anti-tamper engine, called from Dart via FFI.
// Compiled by CMake into libanti_tamper.so and loaded by
// lib/services/native_security_bridge.dart.

#include <cstdio>
#include <cstring>
#include <cstdint>
#include <unistd.h>
#include <dirent.h>

extern "C" {

// Reason-code bitmask: which detection vector tripped (good telemetry).
enum TamperFlags : int32_t {
    CLEAN             = 0,
    FRIDA_IN_MAPS     = 1 << 0,
    FRIDA_THREAD_NAME = 1 << 1,
};

// Decode our own detection signatures at runtime so plaintext needles like
// "frida" never sit in the binary for an attacker to grep.
static void xor_decode(char* dst, const char* enc, size_t n, char key) {
    for (size_t i = 0; i < n; ++i) dst[i] = enc[i] ^ key;
    dst[n] = '\0';
}

// 1) Scan loaded modules for injection artifacts.
static bool check_maps(const char* needle) {
    FILE* fp = fopen("/proc/self/maps", "r");
    if (!fp) return false;
    char line[512];
    bool hit = false;
    while (fgets(line, sizeof(line), fp)) {
        if (strstr(line, needle)) { hit = true; break; }
    }
    fclose(fp);
    return hit;
}

// 2) Scan this process's own thread names for Frida workers.
static bool check_thread_names(const char* needle) {
    DIR* dir = opendir("/proc/self/task");
    if (!dir) return false;
    struct dirent* e;
    bool hit = false;
    while ((e = readdir(dir)) != nullptr) {
        char path[280], comm[64] = {0};
        snprintf(path, sizeof(path), "/proc/self/task/%s/comm", e->d_name);
        FILE* fp = fopen(path, "r");
        if (!fp) continue;
        if (fgets(comm, sizeof(comm), fp) && strstr(comm, needle)) hit = true;
        fclose(fp);
        if (hit) break;
    }
    closedir(dir);
    return hit;
}

// Exported for Dart FFI. Returns a bitmask, not just a bool.
__attribute__((visibility("default"))) __attribute__((used))
int32_t scan_environment() {
    int32_t flags = CLEAN;

    // Signatures stored XOR 0x42, decoded only into stack buffers.
    static const char enc_frida[] = {0x24, 0x30, 0x2b, 0x26, 0x23};       // f r i d a
    static const char enc_gumjs[] = {0x25, 0x37, 0x2f, 0x6f, 0x28, 0x31}; // g u m - j s
    char frida[6], gumjs[7];
    xor_decode(frida, enc_frida, 5, 0x42);
    xor_decode(gumjs, enc_gumjs, 6, 0x42);

    if (check_maps(frida))         flags |= FRIDA_IN_MAPS;
    if (check_thread_names(gumjs)) flags |= FRIDA_THREAD_NAME;
    return flags;
}

} // extern "C"
