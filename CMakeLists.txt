cmake_minimum_required(VERSION 3.20)
project(GanttProject VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick QuickControls2 Widgets OpenGL Svg PrintSupport)

qt6_standard_project_setup()

set(SOURCES
    src/main.cpp
    src/ProjectData.cpp
    src/TaskModel.cpp
    src/GroupModel.cpp
    src/MilestoneModel.cpp
    src/DependencyModel.cpp
    src/HistoryEntry.cpp
    src/ResourceManager.cpp
    src/SettingsManager.cpp
    src/ExportManager.cpp
    src/ProjectController.cpp
    qml.qrc
)

set(HEADERS
    include/ProjectData.h
    include/TaskModel.h
    include/GroupModel.h
    include/MilestoneModel.h
    include/DependencyModel.h
    include/HistoryEntry.h
    include/ResourceManager.h
    include/SettingsManager.h
    include/ExportManager.h
    include/ProjectController.h
    include/GlobalDefines.h
)

add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})

target_include_directories(${PROJECT_NAME} PRIVATE include)

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
)

foreach(RES_FILE ${RESOURCE_FILES})
    get_filename_component(RES_NAME ${RES_FILE} NAME)
    add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/${RES_FILE}
            $<TARGET_FILE_DIR:${PROJECT_NAME}>/${RES_NAME}
    )
endforeach()

set_target_properties(${PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)