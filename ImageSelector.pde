// opens a native file chooser and blocks until the user picks a PNG (or cancels)
// uses a plain Swing dialog (not Processing's selectInput/PSurface) because toggling
// the fullscreen JOGL surface's always-on-top flag from the render thread deadlocks
// against JOGL's own EDT
import javax.swing.JDialog;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.SwingUtilities;
import javax.swing.filechooser.FileNameExtensionFilter;

class ImageSelector {
  PImage result; // image selected by the native file chooser
  boolean done = false; // signals that the Swing callback has finished

  // opens the chooser on the Swing event thread and waits for its result
  PImage select() {
    SwingUtilities.invokeLater(() -> {
      // an always-on-top owner frame is the only public way to force the chooser
      // dialog above the fullscreen game surface (JFileChooser.createDialog is protected)
      JFrame owner = new JFrame();
      owner.setUndecorated(true);
      owner.setAlwaysOnTop(true);
      owner.setBounds(-100, -100, 1, 1);
      owner.setVisible(true);

      JFileChooser chooser = new JFileChooser();
      chooser.setDialogTitle("Select a PNG image");
      chooser.setFileFilter(new FileNameExtensionFilter("PNG Images", "png"));
      int result = chooser.showOpenDialog(owner); // blocks the swing EDT until the user picks or cancels
      owner.dispose();

      complete(result == JFileChooser.APPROVE_OPTION ? chooser.getSelectedFile() : null);
    });
    while (!done) {
      delay(50);
    }
    return result;
  }

  // converts the selected file into a Processing image, or reports a cancel
  void complete(File selection) {
    if (selection == null) {
      println("Image selection cancelled.");
    } else {
      result = loadImage(selection.getAbsolutePath());
    }
    done = true;
  }
}

// convenience wrapper: call this to get a PImage directly
// keeps callers independent of the ImageSelector helper object's lifecycle
PImage selectPNGImage() {
  return new ImageSelector().select();
}
