#pragma once

namespace tt {
class Controller;
}

namespace tt::ui {

// Draws the whole window for one frame and forwards user actions to the controller.
void drawRoot(Controller& controller);

}  // namespace tt::ui
