import 'package:flutter_test/flutter_test.dart';
import 'package:newsai/data/models/setting.dart';

void main() {
  group('Setting model test', () {
    test('fromJson parses full payload correctly', () {
      final json = {
        'id': 1,
        'slug': 'about-us',
        'title': 'About Us',
        'content_html': '<p>About</p>',
        'created_at': '2026-11-13T12:54:00.134570+07:00',
        'updated_at': '2026-11-13T12:54:00.134607+07:00'
      };

      final setting = Setting.fromJson(json);

      expect(setting.id, 1);
      expect(setting.slug, 'about-us');
      expect(setting.title, 'About Us');
      expect(setting.contentHtml, '<p>About</p>');
      expect(setting.createdAt, DateTime.parse('2026-11-13T12:54:00.134570+07:00'));
      expect(setting.updatedAt, DateTime.parse('2026-11-13T12:54:00.134607+07:00'));
    });

    test('toJson produces correct map', () {
      final setting = Setting(
        id: 2,
        slug: 'terms',
        title: 'Terms',
        contentHtml: '<p>Terms</p>',
        createdAt: DateTime.parse('2026-11-13T12:00:00Z'),
        updatedAt: DateTime.parse('2026-11-13T13:00:00Z'),
      );

      final map = setting.toJson();
      expect(map['id'], 2);
      expect(map['slug'], 'terms');
      expect(map['title'], 'Terms');
      expect(map['content_html'], '<p>Terms</p>');
      expect(map['created_at'], '2026-11-13T12:00:00.000Z');
      expect(map['updated_at'], '2026-11-13T13:00:00.000Z');
    });

    test('SettingSchema is defined and contains expected properties', () {
      expect(SettingSchema.name, 'Setting');
      expect(SettingSchema.properties.containsKey('slug'), isTrue);
      expect(SettingSchema.properties.containsKey('contentHtml'), isTrue);
    });
  });
}
