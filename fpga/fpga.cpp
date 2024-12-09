#include "controller.h"
#include "elf.h"
#include "utility.h"
#include <chrono>
#include <exception>
#include <fstream>
#include <iostream>
#include <thread>
#include <vector>

void run_interactive(Controller &controller) {
	char c;
	int run = 0;
	while (true) {
		info("Enter r to run, q to quit, p to get cpu PC(demo)\n");
		c = getchar();
		if (c == 'q')
			break;
		if (c == 'p') { // print pc
			auto pc = controller.get_pc();
			static_assert(sizeof(pc) == 4, "pc size is not 4");
			info("pc: {:08x}\n", pc);
		}
		else if (c == 'r') { // run
			info("CPU start\n");
			auto start = std::chrono::high_resolution_clock::now();
			controller.start_run();
			// to debug cpu at the same time, implement separate thread
			while (true) {
				if (!controller.output_available())
					continue;
				auto c = controller.get_output();
				if (c == 0) break;
				std::cout << c;
			}
			auto end = std::chrono::high_resolution_clock::now();
			auto time = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
			info("time: {}", time);
		}
	}
}

void run_testing(Controller &controller) {
	info("CPU start\n");
	controller.start_run();
	auto start = std::chrono::high_resolution_clock::now();
	while (true) {
		if (!controller.output_available()) {
			using namespace std::chrono_literals;
			std::this_thread::sleep_for(1ms);
			continue;
		}
		auto c = controller.get_output();
		if (c == 0) break;
		std::cout << c << std::flush;
	}
	auto end = std::chrono::high_resolution_clock::now();
	auto time = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
	info("time: {}", time);
}

std::vector<byte> read_file(const char *path) {
	if (!path || strlen(path) == 0)
		return {};
	std::ifstream file(path, std::ios::in | std::ios::binary);
	if (!file)
		throw std::runtime_error("failed to open file: " + std::string(path));
	file.seekg(0, std::ios::end);
	auto size = file.tellg();
	file.seekg(0, std::ios::beg);
	std::vector<byte> bytes(size);
	file.read(reinterpret_cast<char *>(bytes.data()), size);
	return bytes;
}

enum class RunMode { Testing = 0,
					 Interactive = 1 };

void actual(char *ram_path, char *input_path, char *device_path, RunMode mode) {
	using namespace std::chrono;
	auto elf = ElfReader(ram_path);
	auto sections = elf.getSections();
	auto in_data = read_file(input_path);
	Serial serial;
	serial.init_port(device_path);
	info("done init\n");
	std::this_thread::sleep_for(1s);

	Controller controller(serial);

	controller.ping_pong_test();
	info("done ping pong\n");
	std::this_thread::sleep_for(1s);

	for (auto &sec: sections) {
		controller.upload_ram(sec.start, sec.end, sec.content);
		std::this_thread::sleep_for(10ms);
		controller.verify_ram(sec.start, sec.end, sec.content);
		std::this_thread::sleep_for(10ms);
	}
	info("done upload ram\n");
	std::this_thread::sleep_for(1s);

	controller.upload_input(in_data);
	info("done upload input\n");
	std::this_thread::sleep_for(1s);

	// return;
	if (mode == RunMode::Interactive)
		run_interactive(controller);
	else
		run_testing(controller);
}

int main(int argc, char **argv) {
	if (argc < 4) {
		error("usage: path-to-ram [path-to-input] com-port -I(interactive)/-T(testing)\n");
		return 1;
	}
	char *ram_path = argv[1];
	int no_input = argc < 5;
	char *input_path = no_input ? nullptr : argv[2];
	char *comport = argv[argc - 2];
	char param = argv[argc - 1][1];

	auto run_mode = param == 'I' ? RunMode::Interactive : RunMode::Testing;
	try {
		actual(ram_path, input_path, comport, run_mode);
	} catch (std::exception &e) {
		std::cerr << e.what() << std::endl;
		return 1;
	}
	return 0;
}
