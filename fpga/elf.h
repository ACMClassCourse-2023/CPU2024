#include "utility.h"
#include <cstring>
#include <elf.h>
#include <fcntl.h>
#include <gelf.h>
#include <libelf.h>
#include <string>
#include <unistd.h>
#include <vector>

class ElfReader {
public:
	struct Section {
		uint64_t start;            // 段的起始地址
		uint64_t end;              // 段的结束地址
		std::vector<byte> content; // 段的内容
	};

	explicit ElfReader(const std::string &filename) {
		if (elf_version(EV_CURRENT) == EV_NONE) {
			throw std::runtime_error("Failed to initialize libelf.");
		}

		// 打开文件
		fd_ = open(filename.c_str(), O_RDONLY);
		if (fd_ < 0) {
			throw std::runtime_error("Failed to open ELF file.");
		}

		// 解析 ELF 文件
		elf_ = elf_begin(fd_, ELF_C_READ, nullptr);
		if (!elf_ || elf_kind(elf_) != ELF_K_ELF) {
			close(fd_);
			throw std::runtime_error("Not a valid ELF file.");
		}

		loadSections();
	}

	~ElfReader() {
		if (elf_) {
			elf_end(elf_);
		}
		if (fd_ >= 0) {
			close(fd_);
		}
	}

	const std::vector<Section> &getSections() const {
		return sections_;
	}

private:
	int fd_;
	Elf *elf_;
	std::vector<Section> sections_;

	void loadSections() {
		size_t shstrndx;
		if (elf_getshdrstrndx(elf_, &shstrndx) != 0) {
			throw std::runtime_error("Failed to get section header string table index.");
		}

		Elf_Scn *scn = nullptr;
		while ((scn = elf_nextscn(elf_, scn)) != nullptr) {
			GElf_Shdr shdr;
			if (!gelf_getshdr(scn, &shdr)) {
				throw std::runtime_error("Failed to get section header.");
			}

			// 获取段名
			const char *name = elf_strptr(elf_, shstrndx, shdr.sh_name);
			if (!name) {
				throw std::runtime_error("Failed to get section name.");
			}

			if (!(shdr.sh_flags & SHF_ALLOC))
				continue;

			// std::cout << "Section: " << std::endl;
			// std::cout << "  Name: " << name << std::endl;
			// std::cout << "  Start Address: 0x" << std::hex << shdr.sh_addr << std::endl;
			// std::cout << "  End Address: 0x" << std::hex << (shdr.sh_addr + shdr.sh_size) << std::endl;
			// std::cout << "  Size: " << std::dec << shdr.sh_size << " bytes" << std::endl;

			Section section;
			section.start = shdr.sh_addr;
			section.end = shdr.sh_addr + shdr.sh_size;

			// 如果段类型不是 SHT_NOBITS，则读取段内容
			if (shdr.sh_type != SHT_NOBITS) {
				section.content.resize(shdr.sh_size);
				if (shdr.sh_size > 0) {
					Elf_Data *data = elf_getdata(scn, nullptr);
					if (!data || data->d_size < shdr.sh_size) {
						throw std::runtime_error("Failed to read section data.");
					}
					std::memcpy(section.content.data(), data->d_buf, shdr.sh_size);
				}
			}

			sections_.emplace_back(std::move(section));
		}
	}
};
