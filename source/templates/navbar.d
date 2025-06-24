module templates.navbar;

import std.array : appender;
import std.conv : to;

string Navbar() {
    auto result = appender!string;

    result.put(`<nav class="bg-gray-900 border-b border-gray-700">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center h-16">
                <div class="flex items-center h-full">
                    <div class="flex-shrink-0 flex items-center h-full">
                        <h1 class="text-xl font-bold text-gray-900 dark:text-white m-0">Dlango</h1>
                    </div>
                    <div class="hidden md:block ml-10">
                        <div class="flex items-center space-x-4 h-full">
                            <a href="/" class="text-gray-900 dark:text-white hover:text-gray-700 dark:hover:text-gray-300 px-3 py-2 rounded-md text-sm font-medium transition-colors">Home</a>
                            <a href="/hello" class="text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 px-3 py-2 rounded-md text-sm font-medium transition-colors">Hello</a>
                        </div>
                    </div>
                </div>
                <div class="flex items-center h-full">
                </div>
            </div>
        </div>
    </nav>`);

    return result.data;
}
