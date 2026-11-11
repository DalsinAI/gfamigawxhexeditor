// rexx_amiga.cpp - wxHexEditor's ARexx port, WXHEXEDITOR.1, on the GFOpenWX
// Toolkit's wxARexxPort and arexx.class (patch 0007 makes it with the main
// window):
//   OPEN FILE/A      open a file in a new tab
//   SAVE             save the front tab's file
//   GOTO OFFSET/A    move the cursor to OFFSET (decimal, or 0x... hex)
//   GETPOS           RESULT: the cursor's offset
//   GETSIZE          RESULT: the front tab's file length
//   QUIT FORCE/S     close the window (FORCE: and end); a requester that is
//                    up ends as Cancel first
// and the toolkit's ACTIVATE, DEACTIVATE, VERSION, HELP, FAULT.
// RC 10 when there is no tab (or the file could not be opened or saved).
// Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like wxHexEditor.
#include "HexEditorFrame.h"
#include "HexEditor.h"
#include "HexEditorApp.h"
#include <wx/dialog.h>
#include <wx/evtloop.h>
#include <wx/filefn.h>
#include <wx/filename.h>
#include <wx/timer.h>
#include <wx/openlayout/arexx.h>
#include <stdlib.h>

// True when a dialog's own loop is running (a file requester is up): the
// command came inside it
static bool InModalLoop()
{
	wxEventLoopBase *loop = wxEventLoopBase::GetActive();
	return loop != NULL && wxTheApp != NULL && loop != wxTheApp->GetMainLoop();
}

// QUIT while a requester is up: closing the window there deletes the
// dialog under its ShowModal, and the memory list is found broken at exit
// (Guru 81000005). The dialogs end as Cancel, and a timer closes the window
// once their loops are over (a CallAfter could run again inside the ending
// loop and queue itself for ever).
static void Quit(HexEditorFrame *f, bool force, wxARexxCommand *c)
{
	if (InModalLoop()) {
		for (wxWindowList::compatibility_iterator n = wxTopLevelWindows.GetFirst(); n; n = n->GetNext()) {
			wxDialog *d = wxDynamicCast(n->GetData(), wxDialog);
			if (d != NULL && d->IsModal())
				d->EndModal(wxID_CANCEL);
		}
		wxTimer *t = new wxTimer();
		t->Bind(wxEVT_TIMER, [f, force, t](wxTimerEvent&) {
			if (InModalLoop())
				return;
			t->Stop();
			wxTheApp->CallAfter([t] { delete t; });
			Quit(f, force, NULL);
		});
		t->Start(100);
		return;
	}
	if (!f->Close(force) && !force) {
		if (c != NULL)
			c->SetError(5);	// the program said no (unsaved work)
	} else if (force && wxTheApp != NULL)
		wxTheApp->ExitMainLoop();
}

static HexEditor *Front(HexEditorFrame *f, wxARexxCommand& c)
{
	HexEditor *h = f->GetActiveHexEditor();
	if (h == NULL)
		c.SetError(10);
	return h;
}

void AmigaRexxStart(HexEditorFrame *f)
{
	wxARexxPort *rexx = new wxARexxPort("WXHEXEDITOR", "wxHexEditor " _VERSION_);
	rexx->Add("OPEN", "FILE/A", [f](wxARexxCommand& c) {
		wxString file = c.Str(0);
		if (!wxFileExists(file))
			c.SetError(10, 205);	// object not found
		else if (f->OpenFile(wxFileName(file)) == NULL)
			c.SetError(10);
	});
	rexx->Add("QUIT", "FORCE/S", [f](wxARexxCommand& c) {
		Quit(f, c.Switch(0), &c);
	});
	rexx->Add("SAVE", "", [f](wxARexxCommand& c) {
		if (HexEditor *h = Front(f, c))
			if (!h->FileSave(false))
				c.SetError(10);
	});
	rexx->Add("GOTO", "OFFSET/A", [f](wxARexxCommand& c) {
		HexEditor *h = Front(f, c);
		if (h == NULL)
			return;
		wxScopedCharBuffer s = c.Str(0).mb_str();
		char *end = NULL;
		long long off = strtoll(s.data(), &end, 0);
		if (end == s.data() || *end != '\0' || off < 0 || off > h->FileLength())
			c.SetError(10, 115);	// bad number
		else
			h->Goto(off, true);
	});
	rexx->Add("GETPOS", "", [f](wxARexxCommand& c) {
		if (HexEditor *h = Front(f, c))
			c.SetResult(wxString::Format("%lld", (long long)h->CursorOffset()));
	});
	rexx->Add("GETSIZE", "", [f](wxARexxCommand& c) {
		if (HexEditor *h = Front(f, c))
			c.SetResult(wxString::Format("%lld", (long long)h->FileLength()));
	});
	rexx->Open();
	f->Bind(wxEVT_DESTROY, [f, rexx](wxWindowDestroyEvent& ev) {
		if (ev.GetEventObject() == f)
			delete rexx;
		ev.Skip();
	});
}
