use std::path::PathBuf;
use std::sync::Arc;
use std::sync::Mutex;

use anyhow::{Context, Result};
use serde::Serialize;

#[derive(Debug, Clone)]
pub struct TestConfig {
    pub scenario: String,
    pub output_dir: PathBuf,
    pub width: u32,
    pub height: u32,
    pub frame_budget: u32,
    pub exit_after_capture: bool,
}

impl TestConfig {
    pub fn from_env() -> Result<Option<Self>> {
        let enabled = std::env::var("APP_TEST_MODE").unwrap_or_default();
        if enabled != "1" {
            return Ok(None);
        }

        let scenario = std::env::var("APP_TEST_SCENARIO")
            .context("APP_TEST_SCENARIO is required when APP_TEST_MODE=1")?;

        let output_dir = PathBuf::from(
            std::env::var("APP_TEST_OUTPUT_DIR")
                .context("APP_TEST_OUTPUT_DIR is required when APP_TEST_MODE=1")?,
        );

        let width = parse_env_u32("APP_TEST_WIDTH")?.unwrap_or(1440);

        let height = parse_env_u32("APP_TEST_HEIGHT")?.unwrap_or(960);

        let frame_budget = parse_env_u32("APP_TEST_FRAME_BUDGET")?.unwrap_or(3);

        Ok(Some(Self {
            scenario,
            output_dir,
            width,
            height,
            frame_budget,
            exit_after_capture: true,
        }))
    }
}

#[derive(Debug, Clone)]
pub enum Scenario {
    EmptyInbox,
    ValidationError,
    SyncSuccess,
}

impl Scenario {
    pub fn parse(value: &str) -> Result<Self> {
        match value {
            "empty-inbox" => Ok(Self::EmptyInbox),
            "validation-error" => Ok(Self::ValidationError),
            "sync-success" => Ok(Self::SyncSuccess),
            _ => anyhow::bail!("unknown test scenario: {value}"),
        }
    }
}

#[derive(Debug, Clone)]
pub struct AppState {
    pub title: String,
    pub items: Vec<String>,
    pub error: Option<String>,
    pub success: Option<String>,
}

impl AppState {
    pub fn from_scenario(scenario: Scenario) -> Self {
        match scenario {
            Scenario::EmptyInbox => Self {
                title: "Inbox".into(),
                items: vec![],
                error: None,
                success: None,
            },
            Scenario::ValidationError => Self {
                title: "Create project".into(),
                items: vec![],
                error: Some("Project name is required".into()),
                success: None,
            },
            Scenario::SyncSuccess => Self {
                title: "Sync".into(),
                items: vec!["alpha".into(), "beta".into()],
                error: None,
                success: Some("Synced 2 projects".into()),
            },
        }
    }
}

#[derive(Debug, Serialize)]
struct Manifest {
    scenario: String,
    screenshots: Vec<String>,
    title: String,
    error: Option<String>,
    success: Option<String>,
}

pub struct MyApp {
    state: AppState,
    test: Option<TestRuntime>,
    failure: Arc<Mutex<Option<String>>>,
}

pub struct TestRuntime {
    cfg: TestConfig,
    frame_count: u32,
    screenshot_requested: bool,
    captured: bool,
}

impl MyApp {
    pub fn new(test_cfg: Option<TestConfig>, failure: Arc<Mutex<Option<String>>>) -> Result<Self> {
        let state = if let Some(cfg) = &test_cfg {
            let scenario = Scenario::parse(&cfg.scenario)?;
            AppState::from_scenario(scenario)
        } else {
            AppState::from_scenario(Scenario::EmptyInbox)
        };

        let test = test_cfg.map(|cfg| TestRuntime {
            cfg,
            frame_count: 0,
            screenshot_requested: false,
            captured: false,
        });

        Ok(Self {
            state,
            test,
            failure,
        })
    }

    fn poll_screenshot_event(&mut self, ctx: &egui::Context) -> Result<bool> {
        let Some(test) = &mut self.test else {
            return Ok(false);
        };

        let mut screenshot: Option<Arc<egui::ColorImage>> = None;

        ctx.input(|input| {
            for event in &input.events {
                if let egui::Event::Screenshot {
                    user_data, image, ..
                } = event
                {
                    let tag = user_data
                        .data
                        .as_ref()
                        .and_then(|value| value.downcast_ref::<String>());

                    if tag.is_some_and(|tag| tag == "main") {
                        screenshot = Some(image.clone());
                    }
                }
            }
        });

        let Some(image) = screenshot else {
            return Ok(false);
        };

        std::fs::create_dir_all(&test.cfg.output_dir)?;
        let screenshot_path = test.cfg.output_dir.join("01-main.png");
        save_color_image_png(&screenshot_path, &image)?;

        let manifest = Manifest {
            scenario: test.cfg.scenario.clone(),
            screenshots: vec![screenshot_path.to_string_lossy().into_owned()],
            title: self.state.title.clone(),
            error: self.state.error.clone(),
            success: self.state.success.clone(),
        };

        std::fs::write(
            test.cfg.output_dir.join("manifest.json"),
            serde_json::to_vec_pretty(&manifest)?,
        )?;

        test.captured = true;
        Ok(true)
    }

    fn maybe_capture(&mut self, ctx: &egui::Context, frame: &mut eframe::Frame) -> Result<()> {
        if self.poll_screenshot_event(ctx)? {
            let exit_after_capture = self
                .test
                .as_ref()
                .is_some_and(|test| test.cfg.exit_after_capture);

            if exit_after_capture {
                let _ = frame; // Exact exit hook differs a bit across eframe versions.
                ctx.send_viewport_cmd(egui::ViewportCommand::Close);
            }
            return Ok(());
        }

        let Some(test) = &mut self.test else {
            return Ok(());
        };

        test.frame_count += 1;
        if test.captured || test.screenshot_requested || test.frame_count < test.cfg.frame_budget {
            return Ok(());
        }

        test.screenshot_requested = true;
        ctx.send_viewport_cmd(egui::ViewportCommand::Screenshot(egui::UserData::new(
            String::from("main"),
        )));
        ctx.request_repaint();
        Ok(())
    }
}

impl eframe::App for MyApp {
    fn update(&mut self, ctx: &egui::Context, frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |ui| {
            ui.heading(&self.state.title);

            if let Some(error) = &self.state.error {
                ui.colored_label(egui::Color32::RED, error);
            }

            if let Some(success) = &self.state.success {
                ui.colored_label(egui::Color32::GREEN, success);
            }

            if self.state.items.is_empty() {
                ui.label("Nothing here yet");
            } else {
                for item in &self.state.items {
                    ui.label(item);
                }
            }

            ui.add_enabled(false, egui::Button::new("Primary action"));
        });

        if let Err(err) = self.maybe_capture(ctx, frame) {
            if let Ok(mut failure) = self.failure.lock() {
                *failure = Some(format!("{err:#}"));
            }
            eprintln!("test capture failed: {err:#}");
            ctx.send_viewport_cmd(egui::ViewportCommand::Close);
        }
    }
}

pub fn main() -> Result<()> {
    let test_cfg = TestConfig::from_env()?;
    let failure = Arc::new(Mutex::new(None));

    let mut viewport = egui::ViewportBuilder::default();
    if let Some(cfg) = &test_cfg {
        viewport = viewport.with_inner_size([cfg.width as f32, cfg.height as f32]);
    }

    let native_options = eframe::NativeOptions {
        viewport,
        ..Default::default()
    };

    eframe::run_native(
        "Example App",
        native_options,
        Box::new({
            let failure = Arc::clone(&failure);
            move |_cc| {
                Ok(Box::new(MyApp::new(
                    test_cfg.clone(),
                    Arc::clone(&failure),
                )?))
            }
        }),
    )
    .map_err(|err| anyhow::anyhow!(err.to_string()))?;

    let failure = failure
        .lock()
        .map_err(|_| anyhow::anyhow!("test failure state mutex was poisoned"))?;
    if let Some(message) = failure.as_ref() {
        anyhow::bail!("test capture failed: {message}");
    }

    Ok(())
}

fn save_color_image_png(path: &std::path::Path, image: &egui::ColorImage) -> Result<()> {
    let [width, height] = image.size;
    let mut bytes = Vec::with_capacity(width * height * 4);

    for pixel in &image.pixels {
        bytes.extend_from_slice(&pixel.to_array());
    }

    let rgba = image::RgbaImage::from_raw(width as u32, height as u32, bytes)
        .context("failed to convert egui screenshot into RGBA image")?;

    rgba.save(path)?;
    Ok(())
}

fn parse_env_u32(name: &str) -> Result<Option<u32>> {
    let Some(raw) = std::env::var(name).ok() else {
        return Ok(None);
    };

    let value = raw
        .parse()
        .with_context(|| format!("{name} must be a valid u32, got {raw:?}"))?;
    Ok(Some(value))
}
