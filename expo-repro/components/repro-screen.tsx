import { Image } from 'expo-image';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { ScrollEdgeGradientView } from '@/modules/scroll-edge-gradient';
import type { ScrollEdgeGradientMode } from '@/modules/scroll-edge-gradient';

const gradientColors = ['#FC4A20', '#C42E73', '#673DA6', '#1645A4'];

const content = {
  separated: {
    accent: '#58C7FF',
    badge: 'TWO SOURCE COMPOSITOR',
    detail:
      'The Metal field lives behind the screen while React Native cards remain in the registered scroll view.',
    result: 'Color remains available beneath the native edge blur.',
    title: 'The gradient survives.',
  },
  inScroll: {
    accent: '#FF9F43',
    badge: 'ONE SOURCE CONTROL',
    detail:
      'The identical Metal field is inserted into the scroll view, so opaque cards can replace its pixels first.',
    result: 'The compact title receives the card composite instead.',
    title: 'Opaque pixels win.',
  },
} as const;

type ReproScreenProps = {
  mode: ScrollEdgeGradientMode;
};

export function ReproScreen({ mode }: ReproScreenProps) {
  const copy = content[mode];

  return (
    <ScrollView
      alwaysBounceVertical
      automaticallyAdjustContentInsets
      contentContainerStyle={styles.content}
      contentInsetAdjustmentBehavior="automatic"
      showsVerticalScrollIndicator={false}
      style={styles.scrollView}
    >
      <ScrollEdgeGradientView
        colors={gradientColors}
        heightFraction={0.75}
        mode={mode}
        style={styles.gradientAnchor}
      />

      <HeroCard copy={copy} />

      <SectionHeader index="01" title="Run the visual test" />
      <StepCard
        accent={copy.accent}
        detail="Stop when the card crosses beneath the minimized navigation title."
        number="1"
        title="Scroll an opaque card upward"
      />
      <StepCard
        accent={copy.accent}
        detail="The color field should keep its left-to-right spatial identity only in the separated tab."
        number="2"
        title="Watch orange, magenta, and blue"
      />

      <SectionHeader index="02" title="What UIKit receives" />
      <LayerCard mode={mode} />

      <SectionHeader index="03" title="Finite scroll geometry" />
      <MetricGrid />

      <SectionHeader index="04" title="What Expo contributes" />
      <NoteCard
        accent={copy.accent}
        icon="shippingbox.fill"
        text="React owns the content and palette API. A local Expo module owns the UIKit layer placement, scroll registration, and Metal renderer."
        title="One app, one native bridge"
      />
      <NoteCard
        accent={copy.accent}
        icon="iphone.gen3"
        text="This cannot run in Expo Go. Build the development client so Expo Autolinking can include the Swift module."
        title="Development build required"
      />
    </ScrollView>
  );
}

function HeroCard({ copy }: { copy: (typeof content)[ScrollEdgeGradientMode] }) {
  return (
    <View style={styles.heroCard}>
      <View style={[styles.accentRule, { backgroundColor: copy.accent }]} />
      <View style={styles.badgeRow}>
        <Text selectable style={[styles.kicker, { color: copy.accent }]}>
          {copy.badge}
        </Text>
        <View style={styles.sourcePill}>
          <Text selectable style={styles.sourcePillText}>
            {copy.badge.startsWith('TWO') ? '2 SOURCES' : '1 SOURCE'}
          </Text>
        </View>
      </View>
      <Text selectable style={styles.heroTitle}>
        {copy.title}
      </Text>
      <Text selectable style={styles.bodyMuted}>
        {copy.detail}
      </Text>
      <View style={styles.resultRow}>
        <Image source="sf:arrow.turn.down.right" style={styles.resultIcon} tintColor={copy.accent} />
        <Text selectable style={styles.resultText}>
          {copy.result}
        </Text>
      </View>
    </View>
  );
}

function SectionHeader({ index, title }: { index: string; title: string }) {
  return (
    <View style={styles.sectionHeader}>
      <Text selectable style={styles.sectionIndex}>
        {index}
      </Text>
      <Text accessibilityRole="header" selectable style={styles.sectionTitle}>
        {title}
      </Text>
    </View>
  );
}

function StepCard({
  accent,
  detail,
  number,
  title,
}: {
  accent: string;
  detail: string;
  number: string;
  title: string;
}) {
  return (
    <View style={styles.stepCard}>
      <View style={[styles.stepNumber, { backgroundColor: `${accent}24` }]}>
        <Text selectable style={[styles.stepNumberText, { color: accent }]}>
          {number}
        </Text>
      </View>
      <View style={styles.stepCopy}>
        <Text selectable style={styles.cardTitle}>
          {title}
        </Text>
        <Text selectable style={styles.bodyMuted}>
          {detail}
        </Text>
      </View>
    </View>
  );
}

function LayerCard({ mode }: { mode: ScrollEdgeGradientMode }) {
  const separated = mode === 'separated';
  return (
    <View style={styles.layerCard}>
      <LayerRow
        color="#58C7FF"
        detail="Native title and UIScrollEdgeEffect"
        icon="rectangle.topthird.inset.filled"
        title="Navigation plane"
      />
      <Connector label={separated ? 'attenuates foreground' : 'blurs final composite'} />
      <LayerRow
        color="#FFFFFF"
        detail="Opaque React Native cards and text"
        icon="rectangle.stack.fill"
        title="Foreground scroll view"
      />
      {separated ? <Connector label="independent source" /> : null}
      <LayerRow
        color="#C42E73"
        detail={separated ? 'Scroll-synchronized sibling layer' : 'Child of the same scroll source'}
        icon="circle.hexagongrid.fill"
        title="Metal color field"
      />
    </View>
  );
}

function Connector({ label }: { label: string }) {
  return (
    <View style={styles.connector}>
      <View style={styles.connectorLine} />
      <Text selectable style={styles.connectorLabel}>
        {label}
      </Text>
    </View>
  );
}

function LayerRow({
  color,
  detail,
  icon,
  title,
}: {
  color: string;
  detail: string;
  icon: string;
  title: string;
}) {
  return (
    <View style={styles.layerRow}>
      <View style={[styles.layerIconWrap, { backgroundColor: `${color}1F` }]}>
        <Image source={`sf:${icon}`} style={styles.layerIcon} tintColor={color} />
      </View>
      <View style={styles.layerCopy}>
        <Text selectable style={styles.layerTitle}>
          {title}
        </Text>
        <Text selectable style={styles.layerDetail}>
          {detail}
        </Text>
      </View>
    </View>
  );
}

function MetricGrid() {
  const metrics = [
    { label: 'Field height', value: '75%' },
    { label: 'Angular speed', value: '12°/s' },
    { label: 'Scroll ratio', value: '1:1' },
    { label: 'Fade curve', value: 'smoothstep' },
  ];
  return (
    <View style={styles.metricGrid}>
      {metrics.map((metric) => (
        <View key={metric.label} style={styles.metricCard}>
          <Text selectable style={styles.metricValue}>
            {metric.value}
          </Text>
          <Text selectable style={styles.metricLabel}>
            {metric.label}
          </Text>
        </View>
      ))}
    </View>
  );
}

function NoteCard({
  accent,
  icon,
  text,
  title,
}: {
  accent: string;
  icon: string;
  text: string;
  title: string;
}) {
  return (
    <View style={styles.noteCard}>
      <Image source={`sf:${icon}`} style={styles.noteIcon} tintColor={accent} />
      <View style={styles.noteCopy}>
        <Text selectable style={styles.cardTitle}>
          {title}
        </Text>
        <Text selectable style={styles.bodyMuted}>
          {text}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  accentRule: { borderRadius: 999, height: 5, width: 50 },
  badgeRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: 10,
    justifyContent: 'space-between',
  },
  bodyMuted: { color: '#A7A7AE', fontSize: 17, lineHeight: 24 },
  cardTitle: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: '700',
    letterSpacing: -0.35,
    lineHeight: 25,
  },
  connector: { alignItems: 'center', flexDirection: 'row', gap: 10, paddingLeft: 21 },
  connectorLabel: {
    color: '#71717A',
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  connectorLine: { backgroundColor: '#3A3A40', height: 24, width: 2 },
  content: { gap: 14, paddingBottom: 150, paddingHorizontal: 16 },
  gradientAnchor: { height: 0, position: 'absolute', width: 0 },
  heroCard: {
    backgroundColor: '#151517',
    borderColor: '#343438',
    borderCurve: 'continuous',
    borderRadius: 28,
    borderWidth: 1,
    gap: 17,
    padding: 22,
  },
  heroTitle: {
    color: '#FFFFFF',
    fontSize: 34,
    fontWeight: '800',
    letterSpacing: -1.1,
    lineHeight: 38,
  },
  kicker: { flexShrink: 1, fontSize: 12, fontWeight: '800', letterSpacing: 0.7 },
  layerCard: {
    backgroundColor: '#121214',
    borderColor: '#303034',
    borderCurve: 'continuous',
    borderRadius: 26,
    borderWidth: 1,
    gap: 2,
    padding: 18,
  },
  layerCopy: { flex: 1, gap: 3 },
  layerDetail: { color: '#898990', fontSize: 13, lineHeight: 18 },
  layerIcon: { height: 21, width: 21 },
  layerIconWrap: {
    alignItems: 'center',
    borderCurve: 'continuous',
    borderRadius: 14,
    height: 44,
    justifyContent: 'center',
    width: 44,
  },
  layerRow: { alignItems: 'center', flexDirection: 'row', gap: 13, minHeight: 62 },
  layerTitle: { color: '#FFFFFF', fontSize: 16, fontWeight: '700' },
  metricCard: {
    backgroundColor: '#151517',
    borderColor: '#303034',
    borderCurve: 'continuous',
    borderRadius: 22,
    borderWidth: 1,
    flexBasis: '47%',
    flexGrow: 1,
    gap: 5,
    padding: 18,
  },
  metricGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  metricLabel: { color: '#898990', fontSize: 13, fontWeight: '600' },
  metricValue: {
    color: '#FFFFFF',
    fontSize: 25,
    fontVariant: ['tabular-nums'],
    fontWeight: '800',
    letterSpacing: -0.5,
  },
  noteCard: {
    alignItems: 'flex-start',
    backgroundColor: '#151517',
    borderColor: '#303034',
    borderCurve: 'continuous',
    borderRadius: 24,
    borderWidth: 1,
    flexDirection: 'row',
    gap: 14,
    padding: 20,
  },
  noteCopy: { flex: 1, gap: 8 },
  noteIcon: { height: 24, width: 24 },
  resultIcon: { height: 17, width: 17 },
  resultRow: { alignItems: 'center', flexDirection: 'row', gap: 10 },
  resultText: {
    color: '#D7D7DC',
    flex: 1,
    fontSize: 15,
    fontWeight: '700',
    lineHeight: 21,
  },
  scrollView: { backgroundColor: 'transparent', flex: 1 },
  sectionHeader: { gap: 5, paddingHorizontal: 4, paddingTop: 34 },
  sectionIndex: {
    color: '#66666E',
    fontSize: 12,
    fontVariant: ['tabular-nums'],
    fontWeight: '800',
    letterSpacing: 1,
  },
  sectionTitle: {
    color: '#FFFFFF',
    fontSize: 27,
    fontWeight: '800',
    letterSpacing: -0.65,
    lineHeight: 32,
  },
  sourcePill: {
    backgroundColor: '#2B2B2E',
    borderCurve: 'continuous',
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  sourcePillText: {
    color: '#E8E8EA',
    fontSize: 11,
    fontVariant: ['tabular-nums'],
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  stepCard: {
    alignItems: 'flex-start',
    backgroundColor: '#151517',
    borderColor: '#303034',
    borderCurve: 'continuous',
    borderRadius: 24,
    borderWidth: 1,
    flexDirection: 'row',
    gap: 15,
    padding: 20,
  },
  stepCopy: { flex: 1, gap: 8 },
  stepNumber: {
    alignItems: 'center',
    borderCurve: 'continuous',
    borderRadius: 18,
    height: 50,
    justifyContent: 'center',
    width: 50,
  },
  stepNumberText: {
    fontSize: 21,
    fontVariant: ['tabular-nums'],
    fontWeight: '800',
  },
});
