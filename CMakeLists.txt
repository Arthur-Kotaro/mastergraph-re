cmake_minimum_required(VERSION 3.20)
project(GanttProject VERSION 1.0.0 LANGUAGES CXX)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE)
    message(STATUS "CMAKE_BUILD_TYPE not set, defaulting to Release")
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

set(CMAKE_CXX_FLAGS_RELEASE "-O2 -DNDEBUG")

include(CheckIPOSupported)
check_ipo_supported(RESULT IPO_SUPPORTED OUTPUT IPO_ERROR)
if(IPO_SUPPORTED)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
    message(STATUS "LTO enabled for Release build")
else()
    message(STATUS "LTO not supported: ${IPO_ERROR}")
endif()

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick QuickControls2 Widgets OpenGL Svg PrintSupport)

qt6_standard_project_setup()

set(SOURCES
    src/main.cpp
    src/ProjectData.cpp
    src/ProjectSerializer.cpp
    src/TaskModel.cpp
    src/GroupModel.cpp
    src/MilestoneModel.cpp
    src/DependencyModel.cpp
    src/HistoryEntry.cpp
    src/ResourceManager.cpp
    src/SettingsManager.cpp
    src/ExportManager.cpp
    src/ProjectController.cpp
    src/SessionManager.cpp
    src/ProjectValidator.cpp
    src/TaskController.cpp
    src/LocalGraphController.cpp
    src/DependencyController.cpp
    qml.qrc
)

set(HEADERS
    include/ProjectData.h
    include/ProjectSerializer.h
    include/TaskModel.h
    include/GroupModel.h
    include/MilestoneModel.h
    include/DependencyModel.h
    include/HistoryEntry.h
    include/ResourceManager.h
    include/SettingsManager.h
    include/ExportManager.h
    include/ProjectController.h
    include/SessionManager.h
    include/GlobalDefines.h
    include/ProjectValidator.h
    include/TaskController.h
    include/LocalGraphController.h
    include/DependencyController.h
)

# ---------- Основной бинарник ----------
add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})

target_include_directories(${PROJECT_NAME} PRIVATE include)

target_compile_definitions(${PROJECT_NAME} PRIVATE
#    $<$<CONFIG:Release>:QT_NO_DEBUG_OUTPUT>
#    $<$<CONFIG:Release>:QT_NO_WARNING_OUTPUT>
)

target_link_libraries(${PROJECT_NAME}
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
    Qt6::OpenGL
    Qt6::Svg
    Qt6::PrintSupport
)

set(RESOURCE_FILES
    resources/default_typologies.json
    resources/default_tasks.json
    resources/default_holidays.json
)

foreach(RES_FILE ${RESOURCE_FILES})
    get_filename_component(RES_NAME ${RES_FILE} NAME)
    add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/${RES_FILE}
            $<TARGET_FILE_DIR:${PROJECT_NAME}>/${RES_NAME}
        COMMENT "Copying ${RES_NAME} to build directory"
    )
endforeach()

set_target_properties(${PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# ---------- export_renderer (offscreen export) ----------
set(EXPORT_SOURCES
    export_renderer/main.cpp
    src/ProjectData.cpp
    src/ProjectSerializer.cpp
    src/TaskModel.cpp
    src/GroupModel.cpp
    src/MilestoneModel.cpp
    src/DependencyModel.cpp
    src/HistoryEntry.cpp
    src/ResourceManager.cpp
    src/SettingsManager.cpp
    src/ExportManager.cpp
    src/ProjectController.cpp
    src/SessionManager.cpp
    src/ProjectValidator.cpp
    src/TaskController.cpp
    src/LocalGraphController.cpp
    src/DependencyController.cpp
    qml.qrc
)

add_executable(export_renderer ${EXPORT_SOURCES} ${HEADERS})

target_include_directories(export_renderer PRIVATE include)

target_compile_definitions(export_renderer PRIVATE
#    $<$<CONFIG:Release>:QT_NO_DEBUG_OUTPUT>
#    $<$<CONFIG:Release>:QT_NO_WARNING_OUTPUT>
)

target_link_libraries(export_renderer
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
    Qt6::OpenGL
    Qt6::Svg
    Qt6::PrintSupport
)

set_target_properties(export_renderer PROPERTIES MACOSX_BUNDLE FALSE WIN32_EXECUTABLE FALSE)

foreach(RES_FILE ${RESOURCE_FILES})
    get_filename_component(RES_NAME ${RES_FILE} NAME)
    add_custom_command(
        TARGET export_renderer POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/${RES_FILE}
            $<TARGET_FILE_DIR:export_renderer>/${RES_NAME}
        COMMENT "Copying ${RES_NAME} to export_renderer build directory"
    )
endforeach()
