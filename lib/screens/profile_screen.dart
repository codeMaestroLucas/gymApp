import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile updatedProfile) onProfileUpdated;

  const ProfileScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _routineController;
  late TextEditingController _limitationsController;
  late TextEditingController _geminiKeyController;

  late String _selectedObjective;
  late String _selectedExperience;
  late int _defaultDays;
  late int _defaultDuration;

  final List<String> _objectives = [
    'Hipertrofia Muscular',
    'Definição e Emagrecimento',
    'Força Máxima',
    'Resistência & Condicionamento',
  ];

  final List<String> _experienceLevels = [
    'Iniciante',
    'Intermediário',
    'Avançado',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.userProfile;
    _nameController = TextEditingController(text: p.name);
    _weightController = TextEditingController(text: p.weightKg.toString());
    _heightController = TextEditingController(text: p.heightCm.toString());
    _routineController = TextEditingController(text: p.routine);
    _limitationsController = TextEditingController(text: p.limitations);
    _geminiKeyController =
        TextEditingController(text: StorageService().getGeminiApiKey() ?? '');

    _selectedObjective = _objectives.contains(p.objective)
        ? p.objective
        : _objectives.first;
    _selectedExperience = _experienceLevels.contains(p.experienceLevel)
        ? p.experienceLevel
        : _experienceLevels[1];
    _defaultDays = p.defaultDaysPerWeek;
    _defaultDuration = p.defaultDurationMinutes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _routineController.dispose();
    _limitationsController.dispose();
    _geminiKeyController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final weight = double.tryParse(_weightController.text) ?? widget.userProfile.weightKg;
    final height = double.tryParse(_heightController.text) ?? widget.userProfile.heightCm;

    final updated = widget.userProfile.copyWith(
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : widget.userProfile.name,
      weightKg: weight,
      heightCm: height,
      routine: _routineController.text.trim(),
      objective: _selectedObjective,
      experienceLevel: _selectedExperience,
      limitations: _limitationsController.text.trim(),
      defaultDaysPerWeek: _defaultDays,
      defaultDurationMinutes: _defaultDuration,
    );

    await StorageService().saveProfile(updated);
    await StorageService().setGeminiApiKey(_geminiKeyController.text.trim());
    widget.onProfileUpdated(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.cardBackground,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.primaryOrange),
              SizedBox(width: 10),
              Text(
                'Perfil atualizado! Seus novos treinos seguirão estas diretrizes.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double weight = double.tryParse(_weightController.text) ?? 80;
    final double height = double.tryParse(_heightController.text) ?? 180;
    final bmi = height > 0 ? weight / ((height / 100) * (height / 100)) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Perfil do Atleta',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Estes dados calibram as cargas, volumes e diagramas de todos os treinos gerados pela IA',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),

              // Avatar & Nome
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Nome do Atleta',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Medidas Corporais (Peso e Altura) + IMC Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Biometria',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Peso (kg)',
                              prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20),
                              suffixText: 'kg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Altura (cm)',
                              prefixIcon: Icon(Icons.height_rounded, size: 20),
                              suffixText: 'cm',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Índice de Massa Corporal (IMC):',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${bmi.toStringAsFixed(1)} kg/m²',
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Objetivo e Nível
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Objetivo & Nível de Experiência',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedObjective,
                      decoration: const InputDecoration(
                        labelText: 'Objetivo Principal',
                        prefixIcon: Icon(Icons.track_changes_rounded, size: 20),
                      ),
                      dropdownColor: AppColors.cardBackground,
                      items: _objectives.map((obj) {
                        return DropdownMenuItem(
                          value: obj,
                          child: Text(obj, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedObjective = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedExperience,
                      decoration: const InputDecoration(
                        labelText: 'Nível de Treino',
                        prefixIcon: Icon(Icons.fitness_center_rounded, size: 20),
                      ),
                      dropdownColor: AppColors.cardBackground,
                      items: _experienceLevels.map((exp) {
                        return DropdownMenuItem(
                          value: exp,
                          child: Text(exp, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedExperience = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Rotina Diária e Limitações
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rotina & Limitações Articulares',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'A IA evitará exercícios contraindicados e ajustará cadências',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _routineController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Sua Rotina Diária',
                        hintText: 'Ex: Trabalho sentado 8h, caminho 30 min ao dia...',
                        prefixIcon: Icon(Icons.schedule_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _limitationsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Limitações / Dores / Restrições',
                        hintText: 'Ex: Desconforto no ombro esquerdo, evitar impacto...',
                        prefixIcon: Icon(Icons.healing_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Configuração Opcional de Chave do Gemini
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.vpn_key_rounded,
                            size: 18, color: AppColors.accentYellow),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chave de API Gemini (Opcional)',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Se fornecida, as gerações consultarão os modelos generativos online do Google. Se vazia, o motor de IA embutido gera treinos imediatamente offline.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _geminiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Gemini API Key',
                        hintText: 'AIzaSy...',
                        prefixIcon: Icon(Icons.key_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: const Text(
                    'Salvar Alterações do Perfil',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
