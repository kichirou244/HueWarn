import { createApp } from './app.js';
import { config } from './config/environment.js';

const { app, cronService } = createApp();

app.listen(config.port, '0.0.0.0', () => {
  process.stdout.write(`HueWarn server listening on 0.0.0.0:${config.port}\n`);
  cronService.start();
});
