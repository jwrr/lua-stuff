#include <stdio.h>
#include <ncurses.h>


// Open ncurses window
// 
WINDOW *open_window()
{
  WINDOW *win = initscr();
  if (win == NULL) return NULL;
//   refresh();
  noecho();
  raw();
  //  clear();
  return NULL; // win;
}


// Close ncurses window
// 
int close_window(WINDOW *win)
{  
  noraw();
  echo();
  delwin(win);
  endwin();
//   refresh();
  return 0;
}


// ======================================================
// ======================================================


int main()
{
  
  // ======================================================
  // INIT
  
  WINDOW *win = open_window();
//  if (win == NULL) return 1;

  // ======================================================
  // ACTIVE

  int cnt = 0;
  while (1) {
    char ch = getch();
    printf("ch[%d]=%i\r\n", cnt, ch);
    cnt++;
    if (cnt > 50) break;
  }
  
  // ======================================================
  // CLEAN UP
  
  close_window(win);
  return 0;
}

