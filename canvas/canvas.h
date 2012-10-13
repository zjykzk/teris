#ifndef SNAKE_SNAKE_H_
#define SNAKE_SNAKE_H_
#include <list>
#include <utility>

#include "QMainWindow"

extern "C" {
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "luaconf.h"
}

class QTimer;
class list;
class pair;

namespace tetris {
  using std::list;
  using std::pair;
  using std::make_pair;

  class Canvas : public QMainWindow {
    Q_OBJECT

    public:
      Canvas(QWidget *parent=0);
      int over(lua_State *L);;
      int drawRect(lua_State *L);
      int delRect(lua_State *L);
      ~Canvas();

    protected:
      void paintEvent(QPaintEvent *event);
      void keyPressEvent(QKeyEvent *event);

    private slots:
      void start();
      void pause();
      void continue_();

    private:
      static int getGlobalNumber(lua_State *L, const char *name);
      static int getNumberFromTable(lua_State *L, const char *name);
      void registerFunction();
      void loadResources();
      void createToolBar();

      int up_, down_, left_, right_;
      int base_x_, base_y_;
      int step_;
      int update_interval_;
      QTimer *timer_;
      int key_;
      lua_State *L;
      list<pair<int, int> > drawing_rects_;
  };
}

#endif // SNAKE_SNAKE_H_
