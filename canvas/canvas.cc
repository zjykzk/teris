#include "canvas/canvas.h"

#include <cstddef>

#include "QApplication"
#include "QTimer"
#include "QPainter"
#include "QPoint"
#include "QKeyEvent"
#include "QMessageBox"
#include "QAction"
#include "QToolBar"

static int cClosure(lua_State *L) {
  tetris::Canvas *canvas =(tetris::Canvas*)lua_topointer(L,lua_upvalueindex(1));
  typedef int (*func)(tetris::Canvas*, lua_State*);

  func f = (func)lua_topointer(L, lua_upvalueindex(2));
  return f(canvas, L);
}

static int drawRectProxy(tetris::Canvas *canvas, lua_State *L) {
  return canvas->drawRect(L);
}

static int delRectProxy(tetris::Canvas *canvas, lua_State *L) {
  return canvas->delRect(L);
}

static int overProxy(tetris::Canvas *canvas, lua_State *L) {
  return canvas->over(L);
}

namespace tetris {
  Canvas::Canvas(QWidget *parent) : QMainWindow(parent), key_(Qt::Key_unknown),
    L(luaL_newstate()) {
    luaL_openlibs(L); 
    timer_ = new QTimer(this);
    connect(timer_, SIGNAL(timeout()), this, SLOT(update()));
    createToolBar();
    registerFunction();
    loadResources();
  }

  void Canvas::loadResources() {
    if (luaL_loadfile(L, "res/tetris.lua") || lua_pcall(L, 0, 0, 0)) {
      QMessageBox::warning(this, tr("error"), 
          tr(lua_tostring(L, -1)));
      close();
      return;
    }

    update_interval_ = getGlobalNumber(L, "update_interval");
    step_ = getGlobalNumber(L, "step");
  //  QMessageBox::warning(this, tr("error"), 
  //       tr("%1 %2").arg(update_interval_).arg(step_));

    lua_getglobal(L, "window");
    setFixedSize(getNumberFromTable(L, "width") * step_,
        getNumberFromTable(L, "height") * step_ + base_y_);
    lua_pop(L, 1);

    lua_getglobal(L, "tetris");
    up_ = getNumberFromTable(L, "Up");
    down_ = getNumberFromTable(L, "Down");
    left_ = getNumberFromTable(L, "Left");
    right_ = getNumberFromTable(L, "Right");
  }

  int Canvas::over(lua_State *L) {
    QMessageBox::information(this, tr("Canvas Over"), tr("Game Over"));
    return 0;
  }

  int Canvas::getGlobalNumber(lua_State *L, const char *name) {
    lua_getglobal(L, name);
    int ans = (int)lua_tonumber(L, -1);
    lua_pop(L, 1);
    return ans;
  }

  int Canvas::getNumberFromTable(lua_State *L, const char *name) {
    lua_pushstring(L, name);
    lua_gettable(L, -2);
    int ans = (int) lua_tonumber(L, -1);
    lua_pop(L, 1);
    return ans;
  }

  void Canvas::paintEvent(QPaintEvent *event) {
    int direction = -1;
    switch (key_) {
      case Qt::Key_Up:
      case Qt::Key_W: direction = up_; break;
      case Qt::Key_Down:
      case Qt::Key_S: direction = down_; break;
      case Qt::Key_Left:
      case Qt::Key_A: direction = left_; break;
      case Qt::Key_Right:
      case Qt::Key_D: direction = right_; break;
      default: break;
    }

    lua_getglobal(L, "tetris");
    lua_pushstring(L, "move");
    lua_gettable(L, -2);
    lua_pushnumber(L, direction);
    if (lua_pcall(L, 1, 0, 0)) {
      QMessageBox::warning(this, tr("error"), tr(lua_tostring(L, -1)));
    }
    lua_pop(L, 1);

    QPainter p(this);
    for (list<pair<int, int> >::iterator it = drawing_rects_.begin();
        it != drawing_rects_.end(); ++it) {
      p.drawRect(base_x_ + it->first * step_, base_y_ + it->second * step_,
          step_, step_);
    }

    key_ = Qt::Key_unknown;
  }

  void Canvas::keyPressEvent(QKeyEvent *event) {
    key_ = event->key();
  }

  int Canvas::drawRect(lua_State *L) {
    int x = (int) (lua_tonumber(L, 1) - 1), y = (int) (lua_tonumber(L, 2) - 1);
    drawing_rects_.push_back(make_pair(x, y));
    return 0;
  }

  int Canvas::delRect(lua_State *L) {
    if (drawing_rects_.empty()) return 0;
    int x = (int) (lua_tonumber(L, 1) - 1);
    int y = (int) (lua_tonumber(L, 2) - 1);
    for (list<pair<int, int> >::iterator it = drawing_rects_.begin();
        it != drawing_rects_.end(); ++it) {
      if (it->first == x && it->second == y) {
        drawing_rects_.erase(it);
        return 0;
      }
    }
    return 0;
  }

  void Canvas::registerFunction() {
    lua_newtable(L);
    lua_pushlightuserdata(L, (void *)this);
    lua_pushlightuserdata(L, (void *)&drawRectProxy);
    lua_pushcclosure(L, &cClosure, 2);
    lua_setfield(L, -2, "drawRect");

    lua_pushlightuserdata(L, (void *)this);
    lua_pushlightuserdata(L, (void *)&delRectProxy);
    lua_pushcclosure(L, &cClosure, 2);
    lua_setfield(L, -2, "delRect");

    lua_pushlightuserdata(L, (void *)this);
    lua_pushlightuserdata(L, (void *)&overProxy);
    lua_pushcclosure(L, &cClosure, 2);
    lua_setfield(L, -2, "over");

    lua_setglobal(L, "Canvas");
  }

  void Canvas::pause() {
    lua_getglobal(L, "pause");
    if (lua_pcall(L, 0, 0, 0))
      QMessageBox::warning(this, tr("error"), tr(lua_tostring(L, -1)));
    lua_pop(L, 1);
  }

  void Canvas::continue_() {
    lua_getglobal(L, "continue");
    if (lua_pcall(L, 0, 0, 0))
      QMessageBox::warning(this, tr("error"), tr(lua_tostring(L, -1)));
    lua_pop(L, 1);
  }

  void Canvas::start() {
    timer_->start(update_interval_);
    lua_getglobal(L, "start");
    if (lua_pcall(L, 0, 0, 0))
      QMessageBox::warning(this, tr("error"), tr(lua_tostring(L, -1)));
  }

  void Canvas::createToolBar() {
    QAction *start_action = new QAction(tr("&start"), this);
    connect(start_action, SIGNAL(triggered()), this, SLOT(start()));

    QAction *pause_action = new QAction(tr("&pause"), this);
    connect(pause_action, SIGNAL(triggered()), this, SLOT(pause()));

    QAction *cont_action = new QAction(tr("&continue"), this);
    connect(cont_action, SIGNAL(triggered()), this, SLOT(continue_()));

    QToolBar *tool_bar = addToolBar(tr("actions"));
    tool_bar->addAction(start_action);
    tool_bar->addAction(pause_action);
    tool_bar->addAction(cont_action);

    base_x_ = 0;
    base_y_ = tool_bar->height();
  }

  Canvas::~Canvas() {
    lua_close(L);
  }
}

int main(int argc, char *argv[]) {
  using namespace tetris;

  QApplication app(argc, argv);
  Canvas *canvas= new Canvas();
  canvas->show();
  return app.exec();
}
